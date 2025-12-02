#!/bin/bash

echo "=== Kafka Connect Status ==="
curl -s http://localhost:8083/connectors 2>/dev/null | jq . || echo "Kafka Connect not responding"

echo -e "\n=== Connector Status ==="
curl -s http://localhost:8083/connectors/postgres-connector/status 2>/dev/null | jq . || echo "Connector not found"

echo -e "\n=== Kafka Topics ==="
export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto
/opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null || echo "Kafka not responding"

echo -e "\n=== Service Status ==="
sudo systemctl is-active zookeeper kafka kafka-connect
