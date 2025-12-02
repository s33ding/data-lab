#!/bin/bash
KAFKA_DIR="/opt/kafka"

echo "Stopping Kafka services..."
$KAFKA_DIR/bin/kafka-server-stop.sh
$KAFKA_DIR/bin/zookeeper-server-stop.sh
pkill -f "kafka.Kafka"
pkill -f "QuorumPeerMain"
