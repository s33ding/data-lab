# Kafka EC2 Tests

Pytest suite to validate Kafka deployment on EC2 with Debezium and RDS connectivity.

## Prerequisites

1. **Terraform Applied**: Run `terraform apply` to create SSM parameters
2. **EC2 Deployed**: Deploy Kafka to EC2 using scripts in `ec2/` folder
3. **SSH Key**: Update SSH key path in `conftest.py`
4. **Python Environment**: Python 3.7+ with pip

## Test Structure

### Test Categories

1. **Installation Tests** (`test_kafka_installation.py`)
   - Java installation (Amazon Corretto)
   - Kafka installation at `/opt/kafka`
   - Debezium PostgreSQL connector
   - Systemd services creation
   - Configuration files

2. **IAM Permissions Tests** (`test_iam_permissions.py`)
   - Secrets Manager access
   - SSM Parameter Store access
   - EC2 metadata access
   - AWS CLI configuration

3. **Service Tests** (`test_kafka_services.py`)
   - Service status (running)
   - Port listening (2181, 9092, 8083)
   - Kafka Connect REST API
   - Kafka topics command
   - Service logs (no critical errors)

4. **RDS Connectivity Tests** (`test_rds_connectivity.py`)
   - Network connectivity to RDS
   - PostgreSQL client availability
   - RDS authentication
   - Logical replication enabled
   - Debezium connector deployment

## Running Tests

### Setup
```bash
cd test/ec2/
pip install -r requirements.txt

# Update SSH key path in conftest.py
vim conftest.py  # Update key_path variable
```

### Run All Tests
```bash
./run_tests.sh
```

### Run Specific Test Categories
```bash
# Installation only
pytest test_kafka_installation.py -v

# IAM permissions only
pytest test_iam_permissions.py -v

# Services only
pytest test_kafka_services.py -v

# RDS connectivity only
pytest test_rds_connectivity.py -v
```

### Generate HTML Report
```bash
pytest --html=test_report.html --self-contained-html
```

## Parameters Used

Tests retrieve configuration from SSM Parameter Store:

- `/kafka-poc/test/ec2-instance-id` - EC2 instance ID
- `/kafka-poc/test/rds-endpoint` - RDS endpoint
- `/kafka-poc/test/secret-arn` - Secrets Manager ARN
- `/kafka-poc/test/region` - AWS region
- `/kafka-poc/test/kafka-port` - Kafka port (9092)
- `/kafka-poc/test/connect-port` - Kafka Connect port (8083)

## Test Fixtures

- `aws_session` - AWS session for API calls
- `test_parameters` - SSM parameters loaded once per session
- `ec2_client` - EC2 client for instance operations
- `ec2_instance_ip` - Public IP of EC2 instance
- `ssh_client` - SSH connection to EC2 instance

## Expected Results

All tests should pass if:
- EC2 instance is properly configured
- IAM role has required permissions
- Kafka services are running
- RDS has logical replication enabled
- Network connectivity is working

## Troubleshooting

### SSH Connection Issues
- Verify SSH key path in `conftest.py`
- Check security group allows SSH (port 22)
- Ensure EC2 instance is running

### Permission Issues
- Verify IAM role attached to EC2 instance
- Check IAM policies for Secrets Manager and SSM access
- Ensure RDS security group allows EC2 access

### Service Issues
- Check if services were started: `sudo systemctl status kafka`
- Review service logs: `sudo journalctl -u kafka -f`
- Verify ports are not blocked by firewall

### RDS Issues
- Confirm RDS parameter group has logical replication enabled
- Check RDS security group allows EC2 access on port 5432
- Verify RDS instance is in `available` state
