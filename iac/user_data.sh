#!/bin/bash
exec > >(tee /var/log/user-data.log) 2>&1
set -x

# Update system and install dependencies
yum update -y
yum install -y java-11-amazon-corretto wget jq

# Install newer PostgreSQL client for SCRAM authentication
amazon-linux-extras install postgresql14 -y

# Download and install Kafka
cd /opt
wget -O kafka.tgz https://archive.apache.org/dist/kafka/3.5.0/kafka_2.13-3.5.0.tgz
tar -xzf kafka.tgz
mv kafka_2.13-3.5.0 kafka
chown -R ec2-user:ec2-user kafka
chmod +x /opt/kafka/bin/*.sh
rm kafka.tgz

# Download and install Debezium PostgreSQL connector
cd /opt/kafka/libs
wget -O debezium.tar.gz https://repo1.maven.org/maven2/io/debezium/debezium-connector-postgres/2.4.2.Final/debezium-connector-postgres-2.4.2.Final-plugin.tar.gz
tar -xzf debezium.tar.gz
chown -R ec2-user:ec2-user debezium-connector-postgres
rm debezium.tar.gz

# Create Kafka Connect configuration
cat > /home/ec2-user/connect-distributed.properties << 'EOF'
bootstrap.servers=localhost:9092
group.id=connect-cluster
key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter
key.converter.schemas.enable=false
value.converter.schemas.enable=false
offset.storage.topic=connect-offsets
offset.storage.replication.factor=1
config.storage.topic=connect-configs
config.storage.replication.factor=1
status.storage.topic=connect-status
status.storage.replication.factor=1
plugin.path=/opt/kafka/libs
rest.port=8083
EOF

# Create Debezium connector template
cat > /home/ec2-user/postgres-connector.json.template << 'EOF'
{
  "name": "postgres-connector",
  "config": {
    "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
    "database.hostname": "HOST_PLACEHOLDER",
    "database.port": "5432",
    "database.user": "USERNAME_PLACEHOLDER",
    "database.password": "PASSWORD_PLACEHOLDER",
    "database.dbname": "DBNAME_PLACEHOLDER",
    "database.server.name": "postgres-server",
    "table.include.list": "public.*",
    "plugin.name": "pgoutput",
    "slot.name": "debezium_slot"
  }
}
EOF

# Create configure-debezium script
cat > /home/ec2-user/configure-debezium.sh << 'EOF'
#!/bin/bash
set -e

# Get RDS credentials from Secrets Manager
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${rds_secret_name} --region ${aws_region} --query SecretString --output text)

# Parse credentials
HOST=$(echo $SECRET_JSON | jq -r '.host')
USERNAME=$(echo $SECRET_JSON | jq -r '.username')
PASSWORD=$(echo $SECRET_JSON | jq -r '.password')
DBNAME=$(echo $SECRET_JSON | jq -r '.db_name')

# Create connector configuration from template
sed -e "s/HOST_PLACEHOLDER/$HOST/g" \
    -e "s/USERNAME_PLACEHOLDER/$USERNAME/g" \
    -e "s/PASSWORD_PLACEHOLDER/$PASSWORD/g" \
    -e "s/DBNAME_PLACEHOLDER/$DBNAME/g" \
    postgres-connector.json.template > postgres-connector.json

# Deploy connector
curl -X POST -H "Content-Type: application/json" \
     --data @postgres-connector.json \
     http://localhost:8083/connectors

echo "Debezium connector deployed successfully"
EOF

# Create systemd service for Zookeeper
cat > /etc/systemd/system/zookeeper.service << 'EOF'
[Unit]
Description=Apache Zookeeper
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
ExecStop=/opt/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal
WorkingDirectory=/opt/kafka

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for Kafka
cat > /etc/systemd/system/kafka.service << 'EOF'
[Unit]
Description=Apache Kafka
After=zookeeper.service

[Service]
Type=simple
User=ec2-user
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal
WorkingDirectory=/opt/kafka

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for Kafka Connect
cat > /etc/systemd/system/kafka-connect.service << 'EOF'
[Unit]
Description=Kafka Connect
After=kafka.service

[Service]
Type=simple
User=ec2-user
ExecStart=/opt/kafka/bin/connect-distributed.sh /home/ec2-user/connect-distributed.properties
Restart=on-abnormal
WorkingDirectory=/home/ec2-user

[Install]
WantedBy=multi-user.target
EOF

# Set proper ownership
chown ec2-user:ec2-user /home/ec2-user/connect-distributed.properties
chown ec2-user:ec2-user /home/ec2-user/postgres-connector.json.template
chmod +x /home/ec2-user/configure-debezium.sh

# Enable and start services
systemctl daemon-reload
systemctl enable zookeeper kafka kafka-connect
systemctl start zookeeper
sleep 10
systemctl start kafka
sleep 15
systemctl start kafka-connect

# Test RDS connection
echo "Testing RDS connection..." >> /var/log/user-data.log
SECRET=$(aws secretsmanager get-secret-value --secret-id ${rds_secret_name} --region ${aws_region} --query SecretString --output text 2>/dev/null || echo '{}')
if [ "$SECRET" != "{}" ]; then
    DB_HOST=$(echo $SECRET | jq -r .host 2>/dev/null || echo "")
    DB_USER=$(echo $SECRET | jq -r .username 2>/dev/null || echo "")
    DB_PASS=$(echo $SECRET | jq -r .password 2>/dev/null || echo "")
    DB_NAME=$(echo $SECRET | jq -r .db_name 2>/dev/null || echo "")
    
    if [ -n "$DB_HOST" ] && [ -n "$DB_USER" ]; then
        echo "Testing PostgreSQL connection to $DB_HOST..." >> /var/log/user-data.log
        PGPASSWORD="$DB_PASS" psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT version();" >> /var/log/user-data.log 2>&1
        if [ $? -eq 0 ]; then
            echo "RDS connection successful!" >> /var/log/user-data.log
        else
            echo "RDS connection failed!" >> /var/log/user-data.log
        fi
    fi
fi

echo "User data script completed at $(date)" >> /var/log/user-data.log
