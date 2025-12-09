#!/bin/bash

echo "Starting Kafka services..."

# Change to Kafka directory
cd /root/kafka_2.13-3.0.0

# Start Kafka server
echo "Starting Kafka server..."
nohup bin/kafka-server-start.sh config/kraft/server.properties > kafka.log 2>&1 &
KAFKA_PID=$!
echo "Kafka server started with PID: $KAFKA_PID"

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready..."
for i in {1..30}; do
    if bin/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
        echo "Kafka is ready!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

# Start Kafka Connect
echo "Starting Kafka Connect..."
nohup bin/connect-distributed.sh config/connect-distributed.properties > connect.log 2>&1 &
CONNECT_PID=$!
echo "Kafka Connect started with PID: $CONNECT_PID"

# Wait for Connect to be ready
echo "Waiting for Kafka Connect to be ready..."
for i in {1..30}; do
    if curl -s http://localhost:8083/ >/dev/null 2>&1; then
        echo "Kafka Connect is ready!"
        break
    fi
    echo "Waiting... ($i/30)"
    sleep 2
done

# Test services
echo "Testing services..."
echo "Kafka topics:"
bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

echo "Kafka Connect status:"
curl -s http://localhost:8083/ | jq '.' 2>/dev/null || curl -s http://localhost:8083/

echo "Available connectors:"
curl -s http://localhost:8083/connector-plugins | jq '.[].class' 2>/dev/null || echo "jq not available"

# Create connectors
echo "Creating Debezium connector..."
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @/tmp/debezium-postgres-connector.json 2>/dev/null && echo "Debezium connector created!" || echo "Failed to create Debezium connector"

echo "Creating S3 sink connector..."
curl -X POST http://localhost:8083/connectors \
  -H "Content-Type: application/json" \
  -d @/tmp/s3-sink-debezium.json 2>/dev/null && echo "S3 sink connector created!" || echo "Failed to create S3 sink connector"

# Show final status
echo "Final connector status:"
curl -s http://localhost:8083/connectors 2>/dev/null || echo "Could not get connector list"

echo "All services started successfully!"
