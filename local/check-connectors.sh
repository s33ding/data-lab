#!/bin/bash
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk

echo "Checking Kafka Connect status..."
curl -s http://localhost:8083/connectors | jq .

echo -e "\nChecking postgres-connector status..."
curl -s http://localhost:8083/connectors/postgres-connector/status | jq .

echo -e "\nListing Kafka topics..."
/opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
