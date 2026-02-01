#!/bin/bash
set -e

echo "🗑️ Uninstalling Kafka on EKS - Complete Cleanup"

# Delete Kafka UI
echo "🖥️ Removing Kafka UI..."
kubectl delete -f applications/monitoring/kafka-ui/ --ignore-not-found=true

# Delete Kafka Connect
echo "🔌 Removing Kafka Connect..."
kubectl delete connect kafka-connect-proper --ignore-not-found=true

# Delete Kafka Brokers
echo "☕ Removing Kafka Brokers..."
kubectl delete kafka kafka-brokers --ignore-not-found=true

# Delete KRaft Controller
echo "🎛️ Removing KRaft Controller..."
kubectl delete kraftcontroller kraftcontroller --ignore-not-found=true

# Wait for resources to be deleted
echo "⏳ Waiting for resources cleanup..."
sleep 30

# Delete service account and secrets
echo "🔐 Cleaning up IAM resources..."
kubectl delete serviceaccount kafka-connect-sa --ignore-not-found=true
kubectl delete secret kafka-ui-auth --ignore-not-found=true

# Uninstall Confluent Operator
echo "⚙️ Uninstalling Confluent Operator..."
helm uninstall confluent-operator --ignore-not-found

# Delete any remaining PVCs
echo "💾 Cleaning up persistent volumes..."
kubectl delete pvc --all --ignore-not-found=true

echo "✅ Uninstallation Complete!"
echo ""
echo "🧹 Cleanup Summary:"
echo "   - All Kafka components removed"
echo "   - Confluent Operator uninstalled"
echo "   - IAM resources cleaned up"
echo "   - Persistent volumes deleted"
