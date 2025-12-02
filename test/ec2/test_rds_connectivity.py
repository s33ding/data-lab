import pytest
import json

class TestRDSConnectivity:
    
    def test_rds_network_connectivity(self, ssh_client, test_parameters):
        """Test network connectivity to RDS instance"""
        rds_endpoint = test_parameters['rds-endpoint'].split(':')[0]  # Remove port if present
        
        # Test ping (may not work if ICMP is blocked, but worth trying)
        stdin, stdout, stderr = ssh_client.exec_command(f'ping -c 1 -W 5 {rds_endpoint}')
        # Don't assert on ping as it might be blocked
        
        # Test TCP connectivity on port 5432
        stdin, stdout, stderr = ssh_client.exec_command(f'timeout 10 bash -c "echo >/dev/tcp/{rds_endpoint}/5432"')
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, f"Cannot connect to RDS on port 5432. Check security groups and network ACLs"
    
    def test_postgresql_client_available(self, ssh_client):
        """Test if PostgreSQL client is available for testing"""
        # Check if psql is available (might need to install)
        stdin, stdout, stderr = ssh_client.exec_command('which psql')
        exit_code = stdout.channel.recv_exit_status()
        
        if exit_code != 0:
            # Try to install postgresql client
            stdin, stdout, stderr = ssh_client.exec_command('sudo yum install -y postgresql')
            install_exit_code = stdout.channel.recv_exit_status()
            
            if install_exit_code == 0:
                # Verify installation
                stdin, stdout, stderr = ssh_client.exec_command('which psql')
                exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "PostgreSQL client (psql) not available and cannot be installed"
    
    def test_rds_authentication(self, ssh_client, test_parameters):
        """Test RDS authentication using credentials from Secrets Manager"""
        region = test_parameters['region']
        
        # Get RDS credentials
        command = f'aws secretsmanager get-secret-value --secret-id rds-master --region {region} --query SecretString --output text'
        stdin, stdout, stderr = ssh_client.exec_command(command)
        secret_json = stdout.read().decode().strip()
        
        try:
            credentials = json.loads(secret_json)
        except json.JSONDecodeError:
            pytest.fail("Cannot parse RDS credentials from Secrets Manager")
        
        host = credentials['host']
        username = credentials['username']
        password = credentials['password']
        dbname = credentials['db_name']
        
        # Test connection with psql
        psql_command = f'PGPASSWORD="{password}" psql -h {host} -U {username} -d {dbname} -c "SELECT version();" -t'
        stdin, stdout, stderr = ssh_client.exec_command(psql_command)
        exit_code = stdout.channel.recv_exit_status()
        
        if exit_code != 0:
            error_output = stderr.read().decode()
            pytest.fail(f"Cannot authenticate to RDS: {error_output}")
        
        # Verify we got a PostgreSQL version
        output = stdout.read().decode().strip()
        assert 'PostgreSQL' in output, "Connected but didn't get PostgreSQL version"
    
    def test_rds_logical_replication_enabled(self, ssh_client, test_parameters):
        """Test if logical replication is enabled on RDS"""
        region = test_parameters['region']
        
        # Get RDS credentials
        command = f'aws secretsmanager get-secret-value --secret-id rds-master --region {region} --query SecretString --output text'
        stdin, stdout, stderr = ssh_client.exec_command(command)
        secret_json = stdout.read().decode().strip()
        credentials = json.loads(secret_json)
        
        host = credentials['host']
        username = credentials['username']
        password = credentials['password']
        dbname = credentials['db_name']
        
        # Check if logical replication is enabled
        sql_command = "SHOW rds.logical_replication;"
        psql_command = f'PGPASSWORD="{password}" psql -h {host} -U {username} -d {dbname} -c "{sql_command}" -t'
        
        stdin, stdout, stderr = ssh_client.exec_command(psql_command)
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Cannot check logical replication setting"
        
        output = stdout.read().decode().strip()
        assert output == 'on', f"Logical replication is not enabled (current value: {output})"
    
    def test_debezium_connector_deployment(self, ssh_client, test_parameters):
        """Test if Debezium connector can be deployed successfully"""
        connect_port = test_parameters['connect-port']
        region = test_parameters['region']
        
        # First, ensure any existing connector is removed
        stdin, stdout, stderr = ssh_client.exec_command(f'curl -X DELETE http://localhost:{connect_port}/connectors/postgres-connector')
        # Don't assert on this as connector might not exist
        
        # Wait a moment
        time.sleep(2)
        
        # Deploy connector using the configuration script
        stdin, stdout, stderr = ssh_client.exec_command('cd /home/ec2-user && ./configure-debezium.sh')
        exit_code = stdout.channel.recv_exit_status()
        
        if exit_code != 0:
            error_output = stderr.read().decode()
            pytest.fail(f"Failed to deploy Debezium connector: {error_output}")
        
        # Wait for connector to initialize
        time.sleep(5)
        
        # Check connector status
        stdin, stdout, stderr = ssh_client.exec_command(f'curl -s http://localhost:{connect_port}/connectors/postgres-connector/status')
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Cannot get connector status"
        
        status_json = stdout.read().decode()
        try:
            status = json.loads(status_json)
            if 'error_code' in status:
                pytest.fail(f"Connector error: {status['message']}")
            connector_state = status['connector']['state']
            assert connector_state == 'RUNNING', f"Connector not running (state: {connector_state})"
        except (json.JSONDecodeError, KeyError) as e:
            pytest.fail(f"Invalid connector status response: {status_json}")

import time  # Add this import at the top
