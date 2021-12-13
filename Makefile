##import .env
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

GREEN := "\033[0;32m"
NC := "\033[0;0m"
LOG := @sh -c '\
	   printf ${GREEN}; \
	   echo "\n> $$1\n"; \
	   printf ${NC}' VALUE

strimzi_setup: safety_check olm_operator strimzi_operator docker_compose_up create_db_credentials_in_k8s kafka_prerequisites

safety_check:
	${LOG}  "Ensuring connection to dev k8s context"
	sh ./scripts/safety-check.sh

docker_compose_up:
	${LOG}  "Bringing up source and destination DBs..."
	docker-compose up -d

build_image:
	${LOG}  "Building kafka connect container..."
	sh ./build.sh

create_db_credentials_in_k8s: strimzi_create_namespace
	${LOG}  "Create DB credentials for use in K8S secrets..."
	sh ./scripts/secrets.sh

kafka_prerequisites:
	${LOG}  "Bringing up CDC prerquisites.  Kafka, schema-registry, etc."
	kubectl apply -f ./manifests/kafka-namespace.yaml
	helm repo add confluentinc https://confluentinc.github.io/cp-helm-charts/
	helm repo update 
	helm upgrade --install --namespace kafka -f "dependencies.values.yaml" --version 0.5.0 cdc-poc-prerequisites confluentinc/cp-helm-charts

strimzi_create_namespace:
	${LOG}  "Creaing cdc-poc namespace..."
	kubectl apply -f ./manifests/cdc-poc-namespace.yaml

olm_operator:
	$(LOG)  "Installing operator lifecycle manager operator in kubernetes..."
	kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.18.2/crds.yaml
	kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.18.2/olm.yaml
	kubectl wait deployment -n olm --all --for condition=available --timeout 300s

strimzi_operator: olm_operator
	$(LOG)  "Installing Strimzi operator in kubernetes..."
	helm repo add strimzi https://strimzi.io/charts/
	helm repo update
	helm upgrade --install strimzi strimzi/strimzi-kafka-operator \
	  --namespace operators \
	  --set watchAnyNamespace=true \
	  --version 0.20.0

sinks:
	${LOG}  "Installing jdbc sink connectors in kubernetes..."
	kubectl apply -f ./manifests/kafka-connector-jdbc-sink.team.yaml -n cdc-poc
	kubectl apply -f ./manifests/kafka-connector-jdbc-sink.member.yaml -n cdc-poc
	kubectl apply -f ./manifests/kafka-connector-jdbc-sink.team_member.yaml -n cdc-poc
	kubectl apply -f ./manifests/kafka-connector-jdbc-sink.domain_event.yaml -n cdc-poc

helm_install:
	${LOG}  "Installing cdc-poc helm chart..."
	helm upgrade --install cdc-poc ./cdc-poc/ -f ./cdc-poc/values.yaml -n cdc-poc

metrics_setup:
	${LOG}  "Adding prometheus operator..."
	kubectl apply -f ./manifests/metrics-namespace.yaml
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add stable https://charts.helm.sh/stable
	helm upgrade --install prom-stack prometheus-community/kube-prometheus-stack \
	  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
	  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false \
	  --version v10.3.3 \
	  --namespace metrics
	#This was the last version of prom stack that works in this setup.  See this issue before upgrading to newer version: https://github.com/prometheus-community/helm-charts/issues/467

nuke: safety_check
	${LOG}  "Destroying the environment..."
	## This does not uninstall the operators.  If you want to clean up completely, go into docker preferences and hit "Reset Kubernetes Cluster".
	docker-compose down
	kubectl delete namespace cdc-poc --ignore-not-found
	kubectl delete namespace metrics --ignore-not-found
	kubectl delete namespace kafka --ignore-not-found

list_topics:
	docker compose exec kafka /kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --list
