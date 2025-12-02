#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
KAFKA_DIR="/opt/kafka"
LOCAL_DIR="$(dirname "$0")"

echo "Starting Kafka Connect..."
$KAFKA_DIR/bin/connect-distributed.sh $LOCAL_DIR/connect-distributed.properties
