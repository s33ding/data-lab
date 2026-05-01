# SQL Server Kafka Source

This folder contains the SQL Server deployment and Kafka Connect configuration for streaming McDonald's sales data.

## Components

- `sqlserver-deployment.yaml` - SQL Server deployment and service
- `sqlserver-init.yaml` - Database initialization with McDonald's sales schema
- `connector-config.json` - Debezium SQL Server source connector configuration
- `deploy.sh` - Deployment script

## Schema

The `kafka.mcdonalds_sales` table matches the schema from `dataset/random_insert.py`:
- store_id, store_name, transaction_id
- product_code, product_name, category
- quantity, unit_price, total_amount
- payment_method, region, city
- created_at (auto-generated)

## Usage

1. Deploy SQL Server: `./deploy.sh`
2. Configure Kafka Connect with the connector JSON
3. Data changes will stream to topic: `sqlserver.TestDB.kafka.mcdonalds_sales`
