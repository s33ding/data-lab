#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
KAFKA_DIR="/opt/kafka"

echo "Starting Zookeeper..."
$KAFKA_DIR/bin/zookeeper-server-start.sh $KAFKA_DIR/config/zookeeper.properties
