#!/bin/bash
set -e

echo "Setting up Kafka on EC2..."

# Update system
sudo yum update -y
sudo yum install -y java-11-amazon-corretto wget awscli jq

# Download and install Kafka
cd /opt
sudo wget -O kafka.tgz https://archive.apache.org/dist/kafka/3.5.0/kafka_2.13-3.5.0.tgz
sudo tar -xzf kafka.tgz
sudo mv kafka_2.13-3.5.0 kafka
sudo chown -R ec2-user:ec2-user kafka
sudo chmod +x /opt/kafka/bin/*.sh

# Download and install Debezium PostgreSQL connector
cd /opt/kafka/libs
sudo wget -O debezium.tar.gz https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.4.2.Final/debezium-connector-postgres-2.4.2.Final-plugin.tar.gz
sudo tar -xzf debezium.tar.gz
sudo chown -R ec2-user:ec2-user /opt/kafka/libs/debezium-connector-postgres
sudo rm debezium.tar.gz

echo "Kafka setup complete at /opt/kafka"
