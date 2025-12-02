# Debezium PostgreSQL Connector Configuration

## Connector Configuration

### Current Configuration
```json
{
  "name": "postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "${DB_HOST}",
    "database.port": "5432",
    "database.user": "${DB_USERNAME}",
    "database.password": "${DB_PASSWORD}",
    "database.dbname": "${DB_NAME}",
    "topic.prefix": "postgres-server",
    "table.include.list": "public.*",
    "plugin.name": "pgoutput"
  }
}
```

### Configuration Details

#### Connection Settings
- **Host**: Retrieved from AWS Secrets Manager `rds-master` secret
- **Port**: `5432`
- **Database**: Retrieved from AWS Secrets Manager
- **User**: Retrieved from AWS Secrets Manager
- **Password**: Retrieved from AWS Secrets Manager `rds-master` secret

#### CDC Settings
- **Topic Prefix**: `postgres-server`
- **Plugin**: `pgoutput` (PostgreSQL built-in logical replication)
- **Tables**: `public.*` (all tables in public schema)

#### Kafka Settings
- **Bootstrap Servers**: `localhost:9092`
- **Key/Value Converters**: JSON without schemas
- **Group ID**: `connect-cluster`

## Deployment Process

### 1. Automatic Configuration
```bash
./configure-debezium.sh
```

This script:
1. Retrieves RDS credentials from AWS Secrets Manager
2. Creates connector configuration JSON
3. Waits for Kafka Connect to be ready (60s timeout)
4. Deploys connector via REST API

### 2. Manual Configuration
```bash
# Get credentials from Secrets Manager
SECRET=$(aws secretsmanager get-secret-value --secret-id rds-master --region us-east-1 --query SecretString --output text)
DB_HOST=$(echo $SECRET | jq -r '.host')
DB_USERNAME=$(echo $SECRET | jq -r '.username')
DB_PASSWORD=$(echo $SECRET | jq -r '.password')
DB_NAME=$(echo $SECRET | jq -r '.db_name')

# Create connector configuration
cat > /tmp/debezium-postgres-connector.json << EOF
{
  "name": "postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "$DB_HOST",
    "database.port": "5432",
    "database.user": "$DB_USERNAME",
    "database.password": "$DB_PASSWORD",
    "database.dbname": "$DB_NAME",
    "topic.prefix": "postgres-server",
    "table.include.list": "public.*",
    "plugin.name": "pgoutput"
  }
}
EOF

# Deploy connector
curl -X POST -H "Content-Type: application/json" \
  --data @/tmp/debezium-postgres-connector.json \
  http://localhost:8083/connectors
```

## Monitoring and Management

### Check Connector Status
```bash
# List all connectors
curl http://localhost:8083/connectors

# Check specific connector status
curl http://localhost:8083/connectors/postgres-connector/status

# Check connector configuration
curl http://localhost:8083/connectors/postgres-connector/config
```

### Kafka Topics Created
After successful deployment, these topics are created:
- `postgres-server` - Schema changes
- `postgres-server.public.table_name` - Per table CDC data

### List Topics
```bash
/opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```

### Consume CDC Messages
```bash
# Consume from specific table topic
/opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic postgres-server.public.your_table_name \
  --from-beginning

# Consume schema changes
/opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic postgres-server \
  --from-beginning
```

## Troubleshooting

### Common Errors

#### 1. WAL Level Error
```
Error: Postgres server wal_level property must be 'logical' but is: 'replica'
```
**Solution**: Enable `rds.logical_replication=1` and reboot RDS instance

#### 2. Connection Timeout
```
Error: Could not connect to database
```
**Solution**: Check security groups, endpoint, and credentials

#### 3. Permission Denied
```
Error: User does not have replication privileges
```
**Solution**: Grant replication privileges to user

#### 4. Topic Prefix Required
```
Error: The 'topic.prefix' value is invalid: A value is required
```
**Solution**: Use `topic.prefix` instead of `database.server.name`

### Connector Management
```bash
# Delete connector
curl -X DELETE http://localhost:8083/connectors/postgres-connector

# Pause connector
curl -X PUT http://localhost:8083/connectors/postgres-connector/pause

# Resume connector
curl -X PUT http://localhost:8083/connectors/postgres-connector/resume

# Restart connector
curl -X POST http://localhost:8083/connectors/postgres-connector/restart
```

## Performance Tuning

### Connector Configuration Options
```json
{
  "max.batch.size": "2048",
  "max.queue.size": "8192",
  "poll.interval.ms": "1000",
  "snapshot.mode": "initial",
  "slot.name": "debezium_slot"
}
```

### PostgreSQL Settings
- `max_wal_senders`: Increase if multiple connectors
- `wal_keep_size`: Increase for high-volume changes
- `max_replication_slots`: One per connector
