#!/bin/bash
set -e

KAFKA_DIR="/opt/kafka"
KAFKA_VERSION="3.5.0"
SCALA_VERSION="2.13"

echo "Setting up Kafka locally (following IAC pattern)..."

# Create kafka directory
sudo mkdir -p $KAFKA_DIR
cd /tmp

# Download Kafka if not exists
if [ ! -d "$KAFKA_DIR/bin" ]; then
    echo "Downloading Kafka ${KAFKA_VERSION}..."
    wget -O kafka.tgz https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz
    tar -xzf kafka.tgz
    sudo mv kafka_${SCALA_VERSION}-${KAFKA_VERSION}/* $KAFKA_DIR/
    sudo chown -R $USER:$USER $KAFKA_DIR
    sudo chmod +x $KAFKA_DIR/bin/*.sh
    rm kafka.tgz
fi

# Download Debezium PostgreSQL connector
DEBEZIUM_DIR="$KAFKA_DIR/libs/debezium-connector-postgres"
if [ ! -d "$DEBEZIUM_DIR" ]; then
    echo "Downloading Debezium PostgreSQL connector..."
    wget -O debezium.tar.gz https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.4.2.Final/debezium-connector-postgres-2.4.2.Final-plugin.tar.gz
    tar -xzf debezium.tar.gz
    sudo mv debezium-connector-postgres $KAFKA_DIR/libs/
    sudo chown -R $USER:$USER $KAFKA_DIR/libs/debezium-connector-postgres
    rm debezium.tar.gz
fi

echo "Kafka setup complete at $KAFKA_DIR"
