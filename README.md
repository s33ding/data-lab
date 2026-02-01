# Data Lab - Production Data Streaming Platform

![Repository Image](assets/repo-img.png)

> **🚧 Status: In Progress** - Simulating OLTP to OLAP integration with a complete data pipeline: PostgreSQL → Kafka → S3 → Athena with Iceberg tables

Enterprise-grade Apache Kafka deployment platform with Change Data Capture, S3 integration, and comprehensive monitoring for production workloads.

## 🏗️ Architecture

```
OLTP Layer                 Streaming Layer              OLAP Layer
┌─────────────┐           ┌─────────────────┐          ┌──────────────┐
│ PostgreSQL  │──CDC──────│  Kafka Cluster │──────────│  Amazon S3   │
│ SQL Server  │ Debezium  │   (3 Brokers)   │   Sink   │   Storage    │
│             │           │   KRaft Mode    │ Connector│              │
└─────────────┘           └─────────────────┘          └──────────────┘
                                 │                             │
                          ┌─────────────────┐          ┌──────────────┐
                          │ Kafka Connect   │          │ Amazon Athena│
                          │   Platform      │          │ + Iceberg    │
                          └─────────────────┘          │   Tables     │
                                                       └──────────────┘
```

### Kafka Infrastructure Components

**Kafka Cluster (KRaft Mode)**
- 3 broker nodes for high availability and fault tolerance
- KRaft consensus protocol eliminates ZooKeeper dependency
- Distributed across multiple availability zones
- Isolated by security groups for network-level protection

**Kafka Connect Platform**
- Dedicated Connect cluster for scalable data integration
- Debezium CDC connectors for real-time change capture
- S3 sink connectors for data lake ingestion
- Isolated connector workloads with resource management

**Security & Isolation**
- Security groups isolate Kafka infrastructure components
- Network segmentation between OLTP, streaming, and OLAP layers
- IAM roles and IRSA for secure AWS service integration
- Node-level isolation for workload separation

## 🚀 Features

- **High Availability**: 3-broker Kafka cluster with KRaft mode
- **Change Data Capture**: Debezium connectors for PostgreSQL/SQL Server  
- **Cloud Storage**: S3 sink connector for data archival
- **Monitoring**: Kafka UI with authentication
- **Security**: IAM roles, IRSA, node isolation

## 📁 Structure

```
data-lab/
├── eks/                           # EKS cluster & Kubernetes configs
│   ├── iac/                      # IAM policies & roles
│   │   ├── kafka-s3-policy.json
│   │   ├── trust-policy.json
│   │   └── setup-s3-permissions.sh
│   ├── infrastructure/           # Kafka cluster components
│   │   ├── kafka-brokers.yaml
│   │   ├── kraft-controller.yaml
│   │   └── ingress.yaml
│   ├── connectors/               # Kafka Connect & CDC
│   │   ├── configs/             # Connector configurations
│   │   ├── proper-kafka-connect/ # Connect cluster setup
│   │   └── deploy-connectors.sh
│   ├── applications/             # Sample apps & monitoring
│   │   ├── monitoring/          # Kafka UI, Grafana, Prometheus
│   │   └── flask-kafka-integration/
│   ├── postgres/                 # PostgreSQL setup & testing
│   │   ├── dataset/             # Sample data & scripts
│   │   └── postgres-tests/      # Connection & query tests
│   ├── kafka-connect/           # Kafka utilities
│   ├── important-documents/     # Security groups & documentation
│   ├── install-all.sh          # Complete deployment script
│   └── uninstall-all.sh        # Cleanup script
├── nodefolder/                   # Kafka cluster & KRaft nodes
├── ingress/                      # Load balancer & routing
├── s3/                          # S3 buckets & data lake setup
├── athena/                      # Athena queries & Iceberg tables
├── assets/                      # Documentation images
└── README.md                    # Project documentation
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
