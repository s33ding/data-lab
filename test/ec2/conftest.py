import pytest
import boto3
import paramiko
import json
from typing import Dict, Any

@pytest.fixture(scope="session")
def aws_session():
    """AWS session for parameter retrieval"""
    return boto3.Session()

@pytest.fixture(scope="session")
def test_parameters(aws_session) -> Dict[str, str]:
    """Load test parameters from SSM Parameter Store"""
    ssm = aws_session.client('ssm')
    
    parameter_names = [
        '/kafka-poc/test/ec2-instance-id',
        '/kafka-poc/test/rds-endpoint',
        '/kafka-poc/test/secret-name',
        '/kafka-poc/test/region',
        '/kafka-poc/test/kafka-port',
        '/kafka-poc/test/connect-port'
    ]
    
    response = ssm.get_parameters(Names=parameter_names)
    
    params = {}
    for param in response['Parameters']:
        key = param['Name'].split('/')[-1]  # Get last part of parameter name
        params[key] = param['Value']
    
    return params

@pytest.fixture(scope="session")
def ec2_client(aws_session, test_parameters):
    """EC2 client for instance operations"""
    return aws_session.client('ec2', region_name=test_parameters['region'])

@pytest.fixture(scope="session")
def ec2_instance_ip(ec2_client, test_parameters):
    """Get EC2 instance public IP"""
    response = ec2_client.describe_instances(
        InstanceIds=[test_parameters['ec2-instance-id']]
    )
    
    instance = response['Reservations'][0]['Instances'][0]
    public_ip = instance.get('PublicIpAddress')
    
    if not public_ip:
        raise ValueError("EC2 instance does not have a public IP address")
    
    return public_ip

@pytest.fixture(scope="session")
def ssh_client(ec2_instance_ip):
    """SSH client for EC2 instance"""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    # Use EC2 key pair - update this path
    key_path = "/home/roberto/Github/kafka-poc-ec2/fedora-main-kafka.pem"
    
    client.connect(
        hostname=ec2_instance_ip,
        username='ec2-user',
        key_filename=key_path,
        timeout=30
    )
    
    yield client
    client.close()
