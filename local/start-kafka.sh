#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
KAFKA_DIR="/opt/kafka"

echo "Starting Kafka server..."
$KAFKA_DIR/bin/kafka-server-start.sh $KAFKA_DIR/config/server.properties
