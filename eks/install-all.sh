#!/bin/bash
set -e

echo "🚀 Installing Kafka EKS Playground in lab namespace..."

# Create namespace
echo "📁 Creating lab namespace..."
kubectl create namespace lab --dry-run=client -o yaml | kubectl apply -f -

# Add Confluent Helm repository
echo "📦 Adding Confluent Helm repository..."
helm repo add confluentinc https://packages.confluent.io/helm
helm repo update

# Install Confluent Operator
echo "⚙️ Installing Confluent Operator..."
helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes -n lab

# Wait for operator to be ready
echo "⏳ Waiting for Confluent Operator..."
kubectl wait --for=condition=available deployment/confluent-operator --timeout=300s -n lab

# Deploy infrastructure
echo "📦 Deploying Kafka infrastructure..."
kubectl apply -f infrastructure/kraft-controller.yaml -n lab
kubectl apply -f infrastructure/kafka-brokers.yaml -n lab

# Wait for Kafka to be ready
echo "⏳ Waiting for Kafka to be ready..."
kubectl wait --for=condition=ready pod -l platform.confluent.io/type=kafka --timeout=300s -n lab

# Deploy PostgreSQL
echo "🐘 Deploying PostgreSQL..."
kubectl apply -f applications/postgres.yaml -n lab
kubectl wait --for=condition=ready pod -l app=postgres --timeout=180s -n lab

# Setup IAM and S3 permissions
echo "🔐 Setting up S3 permissions..."
cd iac && ./setup-s3-permissions.sh || echo "⚠️ S3 permissions already configured" && cd ..

# Deploy Kafka Connect
echo "🔌 Deploying Kafka Connect..."
cd connectors/proper-kafka-connect
./build-and-push.sh
./deploy.sh
cd ../..

# Wait for Kafka Connect
kubectl wait --for=condition=ready pod -l app=kafka-connect --timeout=300s -n lab

# Create connectors
echo "🔗 Creating connectors..."
sleep 30
kubectl exec -it $(kubectl get pods -l app=kafka-connect -o jsonpath='{.items[0].metadata.name}' -n lab) -n lab -- \
  curl -X POST -H "Content-Type: application/json" \
  --data @/opt/kafka/config/postgres-source.json \
  http://localhost:8083/connectors

kubectl exec -it $(kubectl get pods -l app=kafka-connect -o jsonpath='{.items[0].metadata.name}' -n lab) -n lab -- \
  curl -X POST -H "Content-Type: application/json" \
  --data @/opt/kafka/config/s3-sink-connector.json \
  http://localhost:8083/connectors

# Deploy flask app
echo "🎮 Deploying flask app..."
cd applications/flask-kafka-integration
./docker-build-push.sh
kubectl apply -f deployment.yaml
cd ../..

# Deploy monitoring
echo "📊 Deploying Kafka UI..."
kubectl apply -f applications/monitoring/kafka-ui/ -n lab

echo "✅ Installation complete!"
echo "🌐 Access Kafka UI: http://app.dataiesb.com/kafka-ui"
echo "🎮 Access Playground: http://app.dataiesb.com/playground"
