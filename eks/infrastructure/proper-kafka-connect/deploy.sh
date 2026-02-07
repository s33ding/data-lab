#!/bin/bash

echo "Deploying proper Kafka Connect with S3 connector..."

# Deploy Kafka Connect
kubectl apply -f kafka-connect.yaml

echo "Waiting for Kafka Connect to be ready..."
kubectl wait --for=condition=ready pod -l app=kafka-connect-proper --timeout=600s

echo "Creating S3 sink connector..."
kubectl exec -l app=kafka-connect-proper -- curl -X POST \
  -H "Content-Type: application/json" \
  -d @- http://localhost:8083/connectors < s3-sink-connector.json

echo ""
echo "✅ Proper Kafka Connect with S3 sink deployed!"
echo "Check connectors: kubectl exec -l app=kafka-connect-proper -- curl http://localhost:8083/connectors"
echo "Check S3 bucket: aws s3 ls s3://s33ding-kafka-output/kafka-data/ --recursive"
