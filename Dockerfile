FROM strimzi/kafka:0.20.0-kafka-2.6.0
USER root:root
COPY ./build/ /opt/kafka/plugins/

COPY docker-maven-download.sh /usr/local/bin/docker-maven-download

#
# Set up the plugins directory ...
# https://github.com/debezium/docker-images/blob/master/connect-base/1.6/Dockerfile
#
ENV KAFKA_CONNECT_PLUGINS_DIR=$KAFKA_HOME/connect \
    EXTERNAL_LIBS_DIR=$KAFKA_HOME/external_libs \
    CONNECT_PLUGIN_PATH=$KAFKA_CONNECT_PLUGINS_DIR \
    MAVEN_DEP_DESTINATION=$KAFKA_HOME/libs \
    CONFLUENT_VERSION=5.5.0 \
    AVRO_VERSION=1.9.2 \
    AVRO_JACKSON_VERSION=1.9.13 \
    APICURIO_VERSION=1.3.0.Final

RUN docker-maven-download confluent kafka-connect-avro-converter "$CONFLUENT_VERSION" 16c38a7378032f850f0293b7654aa6bf && \
    docker-maven-download confluent kafka-connect-avro-data "$CONFLUENT_VERSION" 63022db9533689968540f45be705786d && \
    docker-maven-download confluent kafka-avro-serializer "$CONFLUENT_VERSION" b1379606e1dcc5d7b809c82abe294cc7 && \
    docker-maven-download confluent kafka-schema-serializer "$CONFLUENT_VERSION" b68a7eebf7ce6a1b826bd5bbb443b176 && \
    docker-maven-download confluent kafka-schema-registry-client "$CONFLUENT_VERSION" e3631a8a3fe10312a727e9d50fcd5527 && \
    docker-maven-download confluent common-config "$CONFLUENT_VERSION" e1a4dc2b6d1d8d8c2df47db580276f38 && \
    docker-maven-download confluent common-utils "$CONFLUENT_VERSION" ad9e39d87c6a9fa1a9b19e6ce80392fa && \
    docker-maven-download central org/codehaus/jackson jackson-core-asl "$AVRO_JACKSON_VERSION" 319c49a4304e3fa9fe3cd8dcfc009d37 && \
    docker-maven-download central org/codehaus/jackson jackson-mapper-asl "$AVRO_JACKSON_VERSION" 1750f9c339352fc4b728d61b57171613 && \
    docker-maven-download central org/apache/avro avro "$AVRO_VERSION" cb70195f70f52b27070f9359b77690bb && \
    docker-maven-download apicurio "$APICURIO_VERSION" 5b51efdd3b7de64e56177fb46b00ca98

USER 1001
