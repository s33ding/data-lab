#!/bin/bash
set -e

echo "Configuring Debezium PostgreSQL connector for RDS..."

# Get RDS credentials from Secrets Manager
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
SECRET=$(aws secretsmanager get-secret-value --secret-id rds-master --region $REGION --query SecretString --output text)

# Export environment variables for envsubst
export DB_HOST=$(echo "$SECRET" | jq -r '.host')
export DB_USERNAME=$(echo "$SECRET" | jq -r '.username') 
export DB_PASSWORD=$(echo "$SECRET" | jq -r '.password')
export DB_NAME=$(echo "$SECRET" | jq -r '.db_name')

echo "Database Host: $DB_HOST"
echo "Database Name: $DB_NAME"
echo "Username: $DB_USERNAME"

# Create Debezium PostgreSQL connector configuration from template
envsubst < postgres-connector.json.template > postgres-connector.json

echo "Generated config:"
cat postgres-connector.json

# Wait for Kafka Connect to be ready with timeout
echo "Waiting for Kafka Connect to be ready..."
TIMEOUT=60
COUNTER=0
while ! curl -f http://localhost:8083/connectors 2>/dev/null; do
    if [ $COUNTER -ge $TIMEOUT ]; then
        echo "Timeout waiting for Kafka Connect. Is it running?"
        exit 1
    fi
    echo "Waiting for Kafka Connect... ($COUNTER/$TIMEOUT)"
    sleep 2
    COUNTER=$((COUNTER + 2))
done

# Deploy connector
echo "Deploying Debezium connector..."
curl -X POST -H "Content-Type: application/json" --data @postgres-connector.json http://localhost:8083/connectors

echo "Debezium connector configured successfully!"
