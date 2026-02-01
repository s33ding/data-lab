# Infrastructure Components

This directory contains the core Kafka infrastructure components for EKS deployment.

## Components

### Kafka Cluster (`kafka-brokers.yaml`)
- 3-broker Kafka cluster using Confluent Platform
- KRaft mode (no ZooKeeper dependency)
- Dedicated node scheduling with tolerations
- Persistent storage with 10Gi volumes

### KRaft Controller (`kraft-controller.yaml`)
- Kafka metadata management
- Replaces traditional ZooKeeper functionality
- High availability configuration

## Key Features

- **Node Isolation**: Uses `kafka=true:NoSchedule` taint
- **High Availability**: Multi-broker setup with proper replication
- **Storage**: Persistent volumes for data durability
- **Security**: Proper RBAC and network policies

## Deployment

```bash
kubectl apply -f infrastructure/
```
