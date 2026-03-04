#!/bin/bash

echo "Deploying proper Kafka Connect with S3 connector..."

# Create ServiceAccount and RBAC
kubectl apply -f service-account.yaml

# Deploy Kafka Connect
kubectl apply -f kafka-connect.yaml

echo "Waiting for Kafka Connect to be ready..."
for i in {1..60}; do
  POD=$(kubectl get pods -n lab -l platform.confluent.io/type=connect -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "$POD" ]; then
    STATUS=$(kubectl get pod -n lab $POD -o jsonpath='{.status.phase}')
    if [ "$STATUS" = "Running" ]; then
      echo "✅ Kafka Connect pod is running"
      break
    fi
  fi
  echo "Waiting... ($i/60)"
  sleep 5
done

POD=$(kubectl get pods -n lab -l platform.confluent.io/type=connect -o name | head -1)

if [ -z "$POD" ]; then
  echo "⚠️ No Kafka Connect pod found"
  exit 1
fi

echo "Creating S3 sink connector..."
kubectl exec -n lab $POD -- curl -X POST \
  -H "Content-Type: application/json" \
  -d @- http://localhost:8083/connectors < s3-sink-connector.json

echo ""
echo "✅ Proper Kafka Connect with S3 sink deployed!"
echo "Check connectors: kubectl exec -n lab $POD -- curl http://localhost:8083/connectors"
echo "Check S3 bucket: aws s3 ls s3://kafka-data-lake-248189947068/kafka-data/ --recursive"
