#!/bin/bash
set -e

echo "Starting Debezium test setup..."

# Start services
docker-compose up -d

# Wait for services to be ready
echo "Waiting for services to start..."
sleep 30

# Check if Kafka Connect is ready
echo "Checking Kafka Connect status..."
curl -s http://localhost:8083/connectors || echo "Connect not ready yet"

# Wait a bit more
sleep 15

# Create the PostgreSQL connector
echo "Creating PostgreSQL connector..."
curl -X POST \
  -H "Content-Type: application/json" \
  --data @postgres-connector.json \
  http://localhost:8083/connectors

# Check connector status
echo "Checking connector status..."
sleep 5
curl -s http://localhost:8083/connectors/postgres-connector/status | jq '.'

# List Kafka topics
echo "Listing Kafka topics..."
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

echo "Debezium setup complete!"
echo "Monitor logs with: docker-compose logs -f connect"
