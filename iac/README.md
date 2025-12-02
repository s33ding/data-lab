# Kafka EC2 Infrastructure

This Terraform configuration deploys:
- EC2 instance with Kafka and Zookeeper
- RDS MySQL instance
- VPC with public/private subnets
- Security groups for proper connectivity

## Prerequisites

1. AWS CLI configured
2. Terraform installed
3. EC2 key pair created

## Deployment

1. Copy and configure variables:
```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

2. Deploy infrastructure:
```bash
terraform init
terraform plan
terraform apply
```

3. Connect to instance:
```bash
# Use the SSH command from terraform output
terraform output ssh_command
```

## Services

- Kafka: Port 9092
- Zookeeper: Port 2181
- RDS: Port 3306 (accessible from EC2 only)

## Cleanup

```bash
terraform destroy
```
