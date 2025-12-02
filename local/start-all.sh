#!/bin/bash
LOCAL_DIR="$(dirname "$0")"

echo "Starting all Kafka services..."

# Start Zookeeper in background
$LOCAL_DIR/start-zookeeper.sh &
ZOOKEEPER_PID=$!
echo "Zookeeper started (PID: $ZOOKEEPER_PID)"
sleep 5

# Start Kafka in background
$LOCAL_DIR/start-kafka.sh &
KAFKA_PID=$!
echo "Kafka started (PID: $KAFKA_PID)"
sleep 5

# Start Kafka Connect in background
$LOCAL_DIR/start-connect.sh &
CONNECT_PID=$!
echo "Kafka Connect started (PID: $CONNECT_PID)"

echo "All services started. Run ./configure-debezium.sh to setup the connector."
echo "Press Ctrl+C to stop all services."

# Wait for interrupt
trap "echo 'Stopping services...'; $LOCAL_DIR/stop-all.sh; exit" INT
wait
