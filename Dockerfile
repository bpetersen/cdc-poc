FROM strimzi/kafka:0.20.0-kafka-2.6.0
USER root:root
COPY ./build/ /opt/kafka/plugins/
USER 1001
