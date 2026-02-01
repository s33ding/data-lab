# Kafka S3 Infrastructure

This folder contains IAM policies and Kubernetes configurations for Kafka Connect S3 access.

## Files

- `kafka-s3-policy.json` - IAM policy granting S3 access to buckets
- `kafka-connect-rbac.yaml` - Kubernetes ServiceAccount and IAM role configuration  
- `setup-s3-permissions.sh` - Script to create IAM role and service account

## S3 Buckets

- `s3-sink-kafka-output` - Output bucket for Kafka messages
- `s33ding-kafka-input` - Input bucket for Kafka processing

## Setup

Run the setup script:
```bash
./setup-s3-permissions.sh
```

Then update your Kafka Connect deployment to include:
```yaml
spec:
  podTemplate:
    spec:
      serviceAccountName: kafka-connect-sa
```
