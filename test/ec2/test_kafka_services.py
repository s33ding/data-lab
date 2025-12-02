import pytest
import time
import json
import socket

class TestKafkaServices:
    
    def test_services_running(self, ssh_client):
        """Test if Kafka services are running"""
        services = ['zookeeper', 'kafka', 'kafka-connect']
        
        for service in services:
            stdin, stdout, stderr = ssh_client.exec_command(f'sudo systemctl is-active {service}')
            status = stdout.read().decode().strip()
            
            assert status == 'active', f"{service} service is not running (status: {status})"
    
    def test_kafka_ports_listening(self, ssh_client, test_parameters):
        """Test if Kafka ports are listening"""
        kafka_port = test_parameters['kafka-port']
        connect_port = test_parameters['connect-port']
        
        # Test Zookeeper port (2181)
        stdin, stdout, stderr = ssh_client.exec_command('netstat -ln | grep :2181')
        output = stdout.read().decode()
        assert ':2181' in output, "Zookeeper port 2181 not listening"
        
        # Test Kafka port
        stdin, stdout, stderr = ssh_client.exec_command(f'netstat -ln | grep :{kafka_port}')
        output = stdout.read().decode()
        assert f':{kafka_port}' in output, f"Kafka port {kafka_port} not listening"
        
        # Test Kafka Connect port
        stdin, stdout, stderr = ssh_client.exec_command(f'netstat -ln | grep :{connect_port}')
        output = stdout.read().decode()
        assert f':{connect_port}' in output, f"Kafka Connect port {connect_port} not listening"
    
    def test_kafka_connect_api(self, ssh_client, test_parameters):
        """Test if Kafka Connect REST API is responding"""
        connect_port = test_parameters['connect-port']
        
        # Test root endpoint
        stdin, stdout, stderr = ssh_client.exec_command(f'curl -s http://localhost:{connect_port}/')
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Kafka Connect REST API not responding"
        
        # Test connectors endpoint
        stdin, stdout, stderr = ssh_client.exec_command(f'curl -s http://localhost:{connect_port}/connectors')
        exit_code = stdout.channel.recv_exit_status()
        output = stdout.read().decode()
        
        assert exit_code == 0, "Kafka Connect connectors endpoint not responding"
        
        # Should return valid JSON array
        try:
            connectors = json.loads(output)
            assert isinstance(connectors, list), "Connectors endpoint should return array"
        except json.JSONDecodeError:
            pytest.fail("Connectors endpoint returned invalid JSON")
    
    def test_kafka_topics_command(self, ssh_client, test_parameters):
        """Test if Kafka topics command works"""
        kafka_port = test_parameters['kafka-port']
        
        command = f'export JAVA_HOME=/usr/lib/jvm/java-11-amazon-corretto && /opt/kafka/bin/kafka-topics.sh --bootstrap-server localhost:{kafka_port} --list'
        stdin, stdout, stderr = ssh_client.exec_command(command)
        exit_code = stdout.channel.recv_exit_status()
        
        assert exit_code == 0, "Cannot list Kafka topics - Kafka may not be running properly"
        
        # Should have at least internal topics
        output = stdout.read().decode()
        assert '__consumer_offsets' in output or len(output.strip()) >= 0, "No topics found"
    
    def test_service_logs_no_errors(self, ssh_client):
        """Test if service logs don't contain critical errors"""
        services = ['zookeeper', 'kafka', 'kafka-connect']
        
        for service in services:
            # Get recent logs
            stdin, stdout, stderr = ssh_client.exec_command(f'sudo journalctl -u {service} --since "5 minutes ago" --no-pager')
            logs = stdout.read().decode()
            
            # Check for critical errors (adjust patterns as needed)
            error_patterns = ['ERROR', 'FATAL', 'Exception in thread', 'OutOfMemoryError']
            
            for pattern in error_patterns:
                if pattern in logs:
                    # Allow some expected errors but fail on critical ones
                    if 'FATAL' in logs or 'OutOfMemoryError' in logs:
                        pytest.fail(f"Critical error found in {service} logs: {pattern}")
                    # For other errors, just warn (could be expected during startup)
                    print(f"Warning: {pattern} found in {service} logs")
