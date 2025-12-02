import pytest
import json

class TestKafkaInstallation:
    
    def test_java_installed(self, ssh_client):
        """Test if Java is installed"""
        stdin, stdout, stderr = ssh_client.exec_command('java -version')
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Java is not installed or not in PATH"
        
        # Check if it's Amazon Corretto
        stderr_output = stderr.read().decode()
        assert 'Corretto' in stderr_output, "Expected Amazon Corretto Java"
    
    def test_kafka_installed(self, ssh_client):
        """Test if Kafka is installed in /opt/kafka"""
        stdin, stdout, stderr = ssh_client.exec_command('ls -la /opt/kafka/bin/kafka-server-start.sh')
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Kafka is not installed at /opt/kafka"
        
        # Check if executable
        stdin, stdout, stderr = ssh_client.exec_command('test -x /opt/kafka/bin/kafka-server-start.sh')
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Kafka start script is not executable"
    
    def test_debezium_installed(self, ssh_client):
        """Test if Debezium PostgreSQL connector is installed"""
        stdin, stdout, stderr = ssh_client.exec_command('ls -la /opt/kafka/libs/debezium-connector-postgres/')
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Debezium PostgreSQL connector is not installed"
        
        # Check for connector JAR files
        stdin, stdout, stderr = ssh_client.exec_command('find /opt/kafka/libs/debezium-connector-postgres/ -name "*.jar" | wc -l')
        jar_count = int(stdout.read().decode().strip())
        
        assert jar_count > 0, "No Debezium JAR files found"
    
    def test_systemd_services_created(self, ssh_client):
        """Test if systemd services are created"""
        services = ['zookeeper', 'kafka', 'kafka-connect']
        
        for service in services:
            stdin, stdout, stderr = ssh_client.exec_command(f'sudo systemctl list-unit-files | grep {service}.service')
            output = stdout.read().decode()
            
            assert service in output, f"{service} systemd service not found"
    
    def test_kafka_config_exists(self, ssh_client):
        """Test if Kafka configuration files exist"""
        config_files = [
            '/opt/kafka/config/server.properties',
            '/opt/kafka/config/zookeeper.properties',
            '/home/ec2-user/connect-distributed.properties'
        ]
        
        for config_file in config_files:
            stdin, stdout, stderr = ssh_client.exec_command(f'test -f {config_file}')
            exit_code = stdout.channel.recv_exit_status()
            
            assert exit_code == 0, f"Configuration file {config_file} not found"
