# Local Kafka Setup

Scripts to run Kafka locally for development and testing.

## Setup

1. Run the setup script to download and configure Kafka:
   ```bash
   ./setup.sh
   ```

## Usage

### Start all services:
```bash
./start-all.sh
```

### Configure Debezium (after services are running):
```bash
./configure-debezium.sh
```

### Check connector status:
```bash
./check-connectors.sh
```

### Stop all services:
```bash
./stop-all.sh
```

## Services

- **Zookeeper**: Runs on port 2181
- **Kafka**: Runs on port 9092
- **Kafka Connect**: Runs on port 8083

## Debezium Configuration

The `configure-debezium.sh` script automatically:
- Retrieves RDS credentials from AWS Secrets Manager (rds-master)
- Creates PostgreSQL connector configuration
- Deploys the connector to Kafka Connect
