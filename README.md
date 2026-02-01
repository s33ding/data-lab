# Data Lab - Production Data Streaming Platform

![Repository Image](assets/repo-img.png)

Enterprise-grade Apache Kafka deployment platform with Change Data Capture, S3 integration, and comprehensive monitoring for production workloads.

## 🏗️ Architecture

```
Applications → Kafka Cluster → S3 Storage
     ↓            (3 Brokers)       ↑
PostgreSQL → Kafka Connect ────────┘
SQL Server   (Debezium CDC)
```

## 🚀 Features

- **High Availability**: 3-broker Kafka cluster with KRaft mode
- **Change Data Capture**: Debezium connectors for PostgreSQL/SQL Server  
- **Cloud Storage**: S3 sink connector for data archival
- **Monitoring**: Kafka UI with authentication
- **Security**: IAM roles, IRSA, node isolation

## 📁 Structure

```
data-lab/
├── infrastructure/     # Kafka cluster & KRaft controller
├── connectors/        # Kafka Connect & S3 sink
├── applications/      # Sample apps & monitoring
├── iac/              # IAM policies & roles
└── scripts/          # Deployment automation
```

## 🚀 Quick Deploy

```bash
# Install everything
./install-all.sh

# Uninstall everything  
./uninstall-all.sh

# Access Kafka UI
open http://app.dataiesb.com/kafka-ui
```

## 🛠️ Tech Stack

- **Platform**: Amazon EKS, Kubernetes
- **Streaming**: Apache Kafka 7.4.0 (Confluent)
- **CDC**: Debezium 2.4.0
- **Storage**: Amazon S3
- **Monitoring**: Kafka UI, Prometheus

## 📊 Skills Demonstrated

- Container orchestration with Kubernetes
- Event streaming architecture
- Change Data Capture patterns
- AWS cloud integration (EKS, S3, IAM)
- Infrastructure as Code
- DevOps automation
