# Kafka POC Setup Process

## Overview
Complete setup process for local Kafka development environment with Debezium CDC integration to AWS RDS PostgreSQL.

## Prerequisites
- Java 21 installed
- AWS CLI configured
- jq installed
- Access to RDS instance

## Local Kafka Setup

### 1. Initial Setup
```bash
cd local/
./setup.sh
```
Downloads and installs:
- Kafka 3.5.0 at `/opt/kafka`
- Debezium PostgreSQL connector

### 2. Start Services
```bash
./start-all.sh
```
Starts in order:
- Zookeeper (port 2181)
- Kafka (port 9092) 
- Kafka Connect (port 8083)

### 3. Verify Services
```bash
./check-connectors.sh
```

## RDS Configuration for CDC

### 4. Enable Logical Replication
```bash
# Create parameter group
aws rds create-db-parameter-group \
  --db-parameter-group-family postgres17 \
  --description "PostgreSQL 17 with logical replication enabled" \
  --db-parameter-group-name postgres17-logical-replication \
  --region us-east-1

# Enable logical replication
aws rds modify-db-parameter-group \
  --db-parameter-group-name postgres17-logical-replication \
  --parameters "ParameterName=rds.logical_replication,ParameterValue=1,ApplyMethod=pending-reboot" \
  --region us-east-1

# Apply to RDS instance
aws rds modify-db-instance \
  --db-instance-identifier rds-prod \
  --db-parameter-group-name postgres17-logical-replication \
  --region us-east-1

# Reboot when status is 'available'
aws rds reboot-db-instance \
  --db-instance-identifier rds-prod \
  --region us-east-1
```

### 5. Configure Debezium Connector
```bash
./configure-debezium.sh
```

Uses AWS Secrets Manager secret `rds-master` with keys:
- `host`: Database endpoint
- `username`: Database user
- `password`: Database password  
- `db_name`: Database name

## Troubleshooting

### Common Issues
1. **Java not found**: Set `JAVA_HOME=/usr/lib/jvm/java-21-openjdk`
2. **Kafka Connect timeout**: Wait for all services to start (15+ seconds)
3. **wal_level error**: RDS needs `rds.logical_replication=1` and reboot
4. **Connection refused**: Check if services are running with `ps aux | grep kafka`

### Service Management
```bash
# Stop all services
./stop-all.sh

# Check status
curl http://localhost:8083/connectors

# View logs
tail -f kafka-startup.log
```

## File Structure
```
local/
├── setup.sh                    # Download and install Kafka
├── start-all.sh                # Start all services
├── start-zookeeper.sh          # Start Zookeeper only
├── start-kafka.sh              # Start Kafka only  
├── start-connect.sh            # Start Kafka Connect only
├── stop-all.sh                 # Stop all services
├── configure-debezium.sh       # Configure CDC connector
├── check-connectors.sh         # Check connector status
├── connect-distributed.properties # Kafka Connect config
└── README.md                   # Usage instructions
```

## Configuration Details

### Kafka Connect Configuration
- Bootstrap servers: `localhost:9092`
- Group ID: `connect-cluster`
- Plugin path: `/opt/kafka/libs`
- Converters: JSON (no schemas)

### Debezium Connector Configuration
- Connector class: `io.debezium.connector.postgresql.PostgresConnector`
- Topic prefix: `postgres-server`
- Plugin name: `pgoutput`
- Table filter: `public.*`

## Next Steps
1. Wait for RDS parameter changes to apply
2. Test Debezium connector deployment
3. Verify CDC topic creation
4. Monitor data streaming from PostgreSQL changes
