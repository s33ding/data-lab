import pytest
import json

class TestIAMPermissions:
    
    def test_secrets_manager_access(self, ssh_client, test_parameters):
        """Test if EC2 instance can access Secrets Manager"""
        secret_name = test_parameters['secret-name']
        region = test_parameters['region']
        
        # Test getting specific secret (the permission we actually need)
        command = f'aws secretsmanager get-secret-value --secret-id {secret_name} --region {region}'
        stdin, stdout, stderr = ssh_client.exec_command(command)
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Cannot read rds-master secret - check IAM permissions"
        
        # Verify secret contains required keys
        output = stdout.read().decode()
        secret_data = json.loads(output)
        secret_string = json.loads(secret_data['SecretString'])
        
        required_keys = ['host', 'username', 'password', 'db_name']
        for key in required_keys:
            assert key in secret_string, f"Secret missing required key: {key}"
    
    def test_ssm_parameter_access(self, ssh_client, test_parameters):
        """Test if EC2 instance can access SSM Parameter Store"""
        region = test_parameters['region']
        
        # Test reading a parameter
        command = f'aws ssm get-parameter --name "/kafka-poc/test/region" --region {region}'
        stdin, stdout, stderr = ssh_client.exec_command(command)
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Cannot access SSM Parameter Store - check IAM role"
    
    def test_ec2_metadata_access(self, ssh_client):
        """Test if instance can access EC2 metadata (for region detection)"""
        command = 'curl -s http://169.254.169.254/latest/meta-data/placement/region'
        stdin, stdout, stderr = ssh_client.exec_command(command)
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Cannot access EC2 metadata"
        
        region = stdout.read().decode().strip()
        assert len(region) > 0, "Empty region from metadata"
        assert region.startswith('us-'), "Invalid region format"
    
    def test_aws_cli_configured(self, ssh_client):
        """Test if AWS CLI is properly configured"""
        stdin, stdout, stderr = ssh_client.exec_command('aws sts get-caller-identity')
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "AWS CLI not configured or no permissions"
        
        # Verify it's using IAM role
        output = stdout.read().decode()
        identity = json.loads(output)
        
        assert 'assumed-role' in identity['Arn'], "Not using IAM role - check instance profile"
