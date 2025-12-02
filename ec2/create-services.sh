#!/bin/bash
set -e

echo "Creating systemd services..."

# Create systemd service for Zookeeper
sudo tee /etc/systemd/system/zookeeper.service > /dev/null << 'EOF'
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
Environment=JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for Kafka
sudo tee /etc/systemd/system/kafka.service > /dev/null << 'EOF'
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
Environment=JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto

[Install]
WantedBy=multi-user.target
EOF

# Create systemd service for Kafka Connect
sudo tee /etc/systemd/system/kafka-connect.service > /dev/null << 'EOF'
[Unit]
Description=Apache Kafka Connect
After=kafka.service

[Service]
Type=simple
User=ec2-user
ExecStart=/opt/kafka/bin/connect-distributed.sh /home/ec2-user/connect-distributed.properties
ExecStop=/bin/kill -TERM $MAINPID
Restart=on-abnormal
WorkingDirectory=/opt/kafka
Environment=JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto

[Install]
WantedBy=multi-user.target
EOF

# Copy connect configuration to ec2-user home
cp connect-distributed.properties /home/ec2-user/

# Enable and start services
sudo systemctl daemon-reload
sudo systemctl enable zookeeper kafka kafka-connect

echo "Services created and enabled"
