#!/bin/bash
set -e

echo "🗑️ Uninstalling Kafka EKS Playground..."

# Delete connectors first
echo "🔗 Deleting connectors..."
kubectl exec -it $(kubectl get pods -l app=kafka-connect -o jsonpath='{.items[0].metadata.name}') -- \
  curl -X DELETE http://localhost:8083/connectors/postgres-source-connector || true
kubectl exec -it $(kubectl get pods -l app=kafka-connect -o jsonpath='{.items[0].metadata.name}') -- \
  curl -X DELETE http://localhost:8083/connectors/s3-sink-connector || true

# Delete applications
echo "🎮 Deleting flask app..."
kubectl delete -f applications/flask-kafka-integration/deployment.yaml || true

# Delete monitoring
echo "📊 Deleting Kafka UI..."
kubectl delete -f applications/monitoring/kafka-ui/ || true

# Delete Kafka Connect
echo "🔌 Deleting Kafka Connect..."
kubectl delete -f connectors/proper-kafka-connect/kafka-connect.yaml || true

# Delete PostgreSQL
echo "🐘 Deleting PostgreSQL..."
kubectl delete -f applications/postgres.yaml || true

# Delete Kafka infrastructure
echo "📦 Deleting Kafka infrastructure..."
kubectl delete -f infrastructure/kafka-brokers.yaml || true
kubectl delete -f infrastructure/kraft-controller.yaml || true

# Delete IAM resources
echo "🔐 Cleaning up IAM resources..."
aws iam detach-role-policy --role-name kafka-s3-role --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/kafka-s3-policy || true
aws iam delete-role --role-name kafka-s3-role || true
aws iam delete-policy --policy-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/kafka-s3-policy || true

echo "✅ Uninstallation complete!"
