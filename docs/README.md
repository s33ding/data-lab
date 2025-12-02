# Kafka POC Documentation

Complete documentation for the Kafka Proof of Concept with Debezium CDC integration.

## Documentation Structure

### [Setup Process](setup-process.md)
Complete step-by-step setup guide for local Kafka environment and RDS integration.

### [RDS Configuration](rds-configuration.md)
Detailed documentation of RDS PostgreSQL configuration changes for logical replication.

### [Debezium Configuration](debezium-configuration.md)
Debezium connector configuration, deployment, and management guide.

## Quick Start

1. **Setup Local Kafka**
   ```bash
   cd local/
   ./setup.sh
   ./start-all.sh
   ```

2. **Configure RDS for CDC**
   ```bash
   # See rds-configuration.md for complete steps
   aws rds create-db-parameter-group --db-parameter-group-family postgres17 ...
   ```

3. **Deploy Debezium Connector**
   ```bash
   ./configure-debezium.sh
   ```

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   PostgreSQL    │    │      Kafka       │    │   Consumers     │
│   (RDS)         │───▶│   + Debezium     │───▶│   Applications  │
│                 │    │   + Connect      │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Components
- **PostgreSQL RDS**: Source database with logical replication enabled
- **Kafka**: Message broker for CDC events
- **Debezium**: CDC connector capturing database changes
- **Kafka Connect**: Platform running Debezium connector

### Data Flow
1. Database changes occur in PostgreSQL
2. Debezium captures changes via logical replication
3. Changes are published to Kafka topics
4. Consumer applications process CDC events

## Key Files

### Local Setup
- `local/setup.sh` - Install Kafka and Debezium
- `local/start-all.sh` - Start all services
- `local/configure-debezium.sh` - Deploy CDC connector

### Configuration
- `local/connect-distributed.properties` - Kafka Connect configuration
- `/tmp/debezium-postgres-connector.json` - Connector configuration

### AWS Resources
- Parameter Group: `postgres17-logical-replication`
- RDS Instance: `rds-prod`
- Secret: `rds-master`

## Monitoring

### Service Health
```bash
# Kafka Connect
curl http://localhost:8083/

# Connectors
curl http://localhost:8083/connectors

# Connector Status
curl http://localhost:8083/connectors/postgres-connector/status
```

### Kafka Topics
```bash
# List topics
/opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list

# Consume messages
/opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic postgres-server.public.table_name
```

## Troubleshooting

### Common Issues
1. **Java not found** - Set JAVA_HOME
2. **Services not starting** - Check ports and permissions
3. **RDS connection failed** - Verify security groups and credentials
4. **WAL level error** - Enable logical replication and reboot RDS

### Log Files
- `local/kafka-startup.log` - Service startup logs
- Kafka Connect logs in console output
- RDS logs in AWS Console

## Next Steps

1. **Test CDC**: Make database changes and verify Kafka messages
2. **Add Consumers**: Build applications to process CDC events  
3. **Scale**: Add more connectors or partitions as needed
4. **Monitor**: Set up monitoring and alerting for production use
