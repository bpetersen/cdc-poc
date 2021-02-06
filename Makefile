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

## Only install the olm prerequisite if it doesn't exist
OLM_EXISTS := $(shell kubectl get csv -n olm || echo 0)
ifeq ($(OLM_EXISTS), 0)
  $(info "OLM not found.  Now configured to install.")
  strimzi_operator: olm_operator
endif

## Only install the strimzi operator if it doesn't exist
STRIMZI_OPERATOR_EXISTS := $(shell kubectl get csv -n operators || echo 0)
ifeq ($(STRIMZI_OPERATOR_EXISTS), 0)
  $(info "Strimzi Operator not found.  Now configured to install.")
  install_operators: strimzi_operator
endif

strimzi_setup: safety_check docker_compose_up strimzi_create_namespace db_setup create_db_credentials_in_k8s kafka_prerequisites install_operators

safety_check:
	${LOG}  "Ensuring connection to dev k8s context"
	sh ./scripts/safety-check.sh

docker_compose_up:
	${LOG}  "Bringing up source and destination DBs..."
	docker-compose up -d

db_setup:
	${LOG}  "Setting up source database..."
	sleep 2
	until docker-compose exec source-db pg_isready; do sleep 1; done
	psql -h localhost -d postgres -U postgres -f ./scripts/db-setup.sql

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
	${LOG}  "Installing operator lifecycle manager operator in kubernetes..."
	kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.17.0/crds.yaml
	kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.17.0/olm.yaml
	kubectl wait deployment -n olm --all --for condition=available --timeout 300s

strimzi_operator:
	${LOG}  "Installing strimzi operator in kubernetes...  This can take a few minutes to complete."
	kubectl create -f https://operatorhub.io/install/strimzi-kafka-operator.yaml
	## We can't use kubectl wait right off the bat because this line ^^ only creates the operator subscription which we can't use kubectl wait on.  Eventually the deployment (which we can wait on) will come up, but that can take a minute or so.
	sleep 60
	## Then once the deployment is starting, we'll wait for it to be available...
	kubectl wait deployment -n operators --all --for condition=available --timeout 300s

install_operators:

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

