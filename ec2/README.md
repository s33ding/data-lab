# EC2 Kafka Deployment

Manual deployment scripts for Kafka with Debezium on EC2.

## Prerequisites
- EC2 instance with Amazon Linux 2
- IAM role with SecretsManager read access
- Security group allowing ports 9092, 8083

## Deployment Steps

### 1. Copy files to EC2
```bash
scp -i your-key.pem ec2/* ec2-user@your-instance:/home/ec2-user/
```

### 2. SSH to EC2 and run setup
```bash
ssh -i your-key.pem ec2-user@your-instance

# Make scripts executable
chmod +x *.sh

# Install Kafka and Debezium
./setup-kafka.sh

# Create systemd services
./create-services.sh
```

### 3. Start services
```bash
./manage-services.sh start
```

### 4. Configure Debezium
```bash
./configure-debezium.sh
```

### 5. Monitor status
```bash
./check-status.sh
```

## Service Management

```bash
# Start all services
./manage-services.sh start

# Stop all services
./manage-services.sh stop

# Check status
./manage-services.sh status

# Restart all services
./manage-services.sh restart
```

## Files Created

- `/opt/kafka/` - Kafka installation
- `/etc/systemd/system/zookeeper.service` - Zookeeper service
- `/etc/systemd/system/kafka.service` - Kafka service  
- `/etc/systemd/system/kafka-connect.service` - Kafka Connect service
- `/home/ec2-user/connect-distributed.properties` - Connect config
- `/home/ec2-user/postgres-connector.json` - Generated connector config

## Ports Used

- **2181** - Zookeeper
- **9092** - Kafka
- **8083** - Kafka Connect REST API

## Troubleshooting

### Check logs
```bash
sudo journalctl -u zookeeper -f
sudo journalctl -u kafka -f
sudo journalctl -u kafka-connect -f
```

### Verify connectivity
```bash
# Test Kafka Connect
curl http://localhost:8083/

# List connectors
curl http://localhost:8083/connectors

# Check topics
/opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
```
