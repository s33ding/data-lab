#!/bin/bash

echo "Creating Playground S3 Sink Connector..."

# Check if Kafka Connect is available
kubectl wait --for=condition=ready pod -l app=kafka-connect --timeout=60s

# Create the S3 sink connector using the JSON config
kubectl exec kafka-connect-0 -- curl -X POST \
  -H "Content-Type: application/json" \
  -d "$(cat configs/playground-s3-sink-connector.json)" \
  http://localhost:8083/connectors

echo ""
echo "Playground S3 Sink Connector created!"
echo "Check status: kubectl exec kafka-connect-0 -- curl http://localhost:8083/connectors/playground-s3-sink-connector/status"
echo "S3 Bucket: s33ding-kafka-output"
