# CDC-POC

This is a proof of concept for deploying a Debezium based change data capture project using helm and strimzi on top of kubernetes.

As part of any CDC deployment using Debezium, the following are required:

1. Kafka
2. Kafka Connect with Debezium jars installed on the container image
3. Schema Registry for using Avro encoded messages
4. A source database (PostgreSQL, MySQL, Cassandra or any other Debezium supported database)

The basic flow for building a CDC deployment looks like this:

1. Decide which tables you want to export from your source database. Ideally these are outbox tables that are written to in the same transaction as your internal tables. Note: this different than the Debezium outbox router.
2. Deploy a Kafka Connect instance for your BC that is connected to kafka.
3. Create a Debezium source job by posting a job configuration to kafka connect's REST endpoint.
4. Monitoring kafka connect tasks.

This project is intended to provide an easy way to set up the necessary compnents. Notice that normally there's some manual intervention in the deployment, specifically hitting a REST api to deploy the kafka connect jobs. The Strimzi operator makes it easy to deploy connectors by simply applying a KafkaConnector CRD.

## What is in this project?

This project gives you the necessary components to test a CDC deployment with Strimzi on your local environment:

1. Source and Destination test databases with example data for sending and receiving CDC data
2. The infrastructure needed for Kafka Connect (kafka, schema registry, etc)
3. The infrastructure needed for monitoring via prometheus (prometheus operator, prometheus, etc)
4. A helm chart to allow you to easily create (and/or deploy) the required Strimzi manifests

- KakfaConnect with
  - secrets provided by kubernetes
  - JMX metrics exported for prometheus consumption
- KafkaConnector(s)
  - Change Event Connector - used to monitor all changes to an approved list of tables. Tombstones will be sent when a record is removed from the source database.
  - Domain Event Connector - used to monitor domain event tables. Tombstones are not submitted.

## Run the Demo

1. Have a kubernetes cluster you can deploy to. I used docker-desktop.
2. Have the folliwng prerequisites installed locally:

- kubectl
- make
- helm

3. Copy example.env to .env and modify settings in .env if needed (running on linux and need to point to minikube).
4. Build the kafka-connect image: `make build_image`
5. Run `make strimzi_setup`
6. Run `make metrics_setup` to install kube-prom-stack. This will enable us to deploy pod monitors and get metrics sent to grafana with prometheus.
7. Modify the `./cdc-poc/values.yaml` to suit your needs. Do you want to run with metrics? Set that in the values file.
8. After the pods have stabilized, run `make helm_install` which will deploy the KafkaConnect and KafkaConnector CRDs.
9. Run `make sinks` to install the sink manifests so that you can verify data is actually being captured. You can (and should) tail the kafka logs to see the data come in. These sinks may make it easier to demo data transit by querying the destination database.

### Metrics

10. Port forward `/web:9090` on the prometheus pod to `localhost:9090`. Verify there is atarget for kafka connect. It will probably be the very last target in the list found at `http://localhost:9090/targets`.
11. Port forward `/grafana:3000` on the grafana pod to `localhost:3000`. Navigate in your browser to `localhost:3000`. Credentials for grafana are user: `admin`, password: `prom-operator`.
12. Load the `grafana-dashboard.json` dashboard in grafana.

## More on Metrics

You will find the `grafana-dashboard.json` in the root directory. It may need to be modified to fit your installation, but it will give you a good start. This file is a slightly modified version of this one: https://github.com/debezium/debezium-examples/blob/master/monitoring/debezium-grafana/debezium-dashboard.json

## Gotchas

1. Postgres might not be quite ready when installing the database. If it dies on `pg_isready`, just run `make strimzi_setup` a second time. It should be ready after a few seconds.
2. The operators can take some time to come to life in kubernetes. Sometimes it will timeout. In that case, run `make strimzi_setup` again after a few minutes. If that doesn't work, it's possible the pods are not coming up due to other issues (e.g., disk pressure, etc.). Check your k8s UI of choice (e.g., lens, k9s, etc.) and see if the pods are not coming up for a particular reason. This is a pretty heavy project to run. You might need to allocate additional resources to docker.

## Helpful Scripts

## To check status of operator

1. `kubectl get csv -n olm` - Check status of OLM
2. `kubectl get csv -n operators` - Check status of Strimzi Operator
3. `kubectl get deployment -n operators` - If this doesn't come back with anything, the operator might still be loading. If thats the case, let's check that the subscription exists...
4. `kubectl get subscription -n operators` - If this doesn't come back with anything, something more serious happened during the install. Check the logs from when you ran `make strimzi_all` earlier in the process. If there is a subscription, just wait another minute and try step 1 again.

### Port Forward

kubectl port-forward <podId> <host-port>:<pod-port>

## Kafka Commands

The commands require a connection to the kafka brokers and in this project, Kafka is running in kubernetes. That will make connecting to the brokers from a host using the kafka command line utilites a little tricky. Instead, shell into the broker pod to run the commands below. K9s and Lens both make it easy to shell into particular pods.

### List Topics

`kafka-topics --list --bootstrap-server localhost:9092`

### Tail Topic

`kafka-console-consumer --bootstrap-server localhost:9092 --topic <topic> --from-beginning`

### Troubleshooting Connectors

If you need to know if a connector was not deployed properly, you'll need to check kubernetes. Look under the status section for information.

`kubectl describe kafkaconnector -n namespace`

### Helm

Test the chart:
`helm install . --dry-run --generate-name`
