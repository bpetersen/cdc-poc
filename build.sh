#!/bin/bash
mkdir build
DEBEZIUM_VERSION=1.3.1
CONTAINER_IMAGE=cdc-poc/strimzi-debezium-kafka-connect

## See instructions here: https://strimzi.io/docs/operators/latest/deploying.html#creating-new-image-from-base-str

## Debezium plugins for all their supported databases
curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-mysql/${DEBEZIUM_VERSION}.Final/debezium-connector-mysql-${DEBEZIUM_VERSION}.Final-plugin.tar.gz | tar xvz --directory build
curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-mongodb/${DEBEZIUM_VERSION}.Final/debezium-connector-mongodb-${DEBEZIUM_VERSION}.Final-plugin.tar.gz | tar xvz --directory build
curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/${DEBEZIUM_VERSION}.Final/debezium-connector-postgres-${DEBEZIUM_VERSION}.Final-plugin.tar.gz | tar xvz --directory build
curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-oracle/${DEBEZIUM_VERSION}.Final/debezium-connector-oracle-${DEBEZIUM_VERSION}.Final-plugin.tar.gz | tar xvz --directory build
curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-sqlserver/${DEBEZIUM_VERSION}.Final.Final/debezium-connector-sqlserver-${DEBEZIUM_VERSION}.Final-plugin.tar.gz | tar xvz --directory build
curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-cassandra/${DEBEZIUM_VERSION}.Final/debezium-connector-cassandra-${DEBEZIUM_VERSION}.Final-plugin.tar.gz | tar xvz --directory build
curl https://repo1.maven.org/maven2/io/debezium/debezium-connector-db2/${DEBEZIUM_VERSION}.Final/debezium-connector-db2-${DEBEZIUM_VERSION}.Final-plugin.tar.gz | tar xvz --directory build

## Generic jdbc sink for testing purposes
wget -nc https://d1i4a15mxbxib1.cloudfront.net/api/plugins/confluentinc/kafka-connect-jdbc/versions/10.0.1/confluentinc-kafka-connect-jdbc-10.0.1.zip -O ./build/kafka-connect-jdbc.zip
unzip ./build/kafka-connect-jdbc.zip -d ./build/
rm ./build/kafka-connect-jdbc.zip

docker build . \
  --tag ${CONTAINER_IMAGE}:${DEBEZIUM_VERSION} \
  --tag ${CONTAINER_IMAGE}:latest \
