#!/bin/bash

POD_NAME="kafka-connect-proper-0"
CONNECT_URL="http://localhost:8083"

echo "Deploying PostgreSQL source connector..."
kubectl exec $POD_NAME -- curl -X POST $CONNECT_URL/connectors \
  -H "Content-Type: application/json" \
  -d "$(cat configs/postgres-source-connector.json)"

echo -e "\n\nDeploying S3 sink connector..."
kubectl exec $POD_NAME -- curl -X POST $CONNECT_URL/connectors \
  -H "Content-Type: application/json" \
  -d "$(cat configs/s3-sink-connector.json)"

echo -e "\n\nChecking connector status..."
kubectl exec $POD_NAME -- curl -X GET $CONNECT_URL/connectors
