#!/bin/bash

echo "Stopping Kafka services..."

# Stop Kafka Connect
echo "Stopping Kafka Connect..."
pkill -f connect-distributed
sleep 3

# Stop Kafka server
echo "Stopping Kafka server..."
pkill -f kafka-server-start
sleep 3

# Force kill all Kafka processes
echo "Force killing all Kafka processes..."
sudo pkill -9 -f kafka
sudo pkill -9 -f connect

# Free up ports
echo "Freeing up ports..."
sudo fuser -k 9092/tcp 2>/dev/null
sudo fuser -k 9093/tcp 2>/dev/null
sudo fuser -k 8083/tcp 2>/dev/null

# Wait for ports to be freed
sleep 5

# Verify no processes are running
KAFKA_PROCS=$(ps aux | grep -E "(kafka|connect)" | grep -v grep | wc -l)
if [ $KAFKA_PROCS -gt 0 ]; then
    echo "Warning: Some Kafka processes may still be running"
    ps aux | grep -E "(kafka|connect)" | grep -v grep
else
    echo "All Kafka services stopped successfully!"
fi
