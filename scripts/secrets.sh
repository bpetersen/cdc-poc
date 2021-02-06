#!/bin/bash
cat <<EOF > db-credentials-debezium.properties
pg_username: postgres
pg_password: postgres
EOF
kubectl -n cdc-poc create secret generic db-credentials-debezium \
  --from-file=db-credentials-debezium.properties
rm db-credentials-debezium.properties
