#!/usr/bin/env python3
import subprocess
import json
import time

POD_NAME = "kafka-connect-0"
NAMESPACE = "lab"

def run(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    return result.stdout, result.returncode

def deploy_connector(config_file, name):
    print(f"📦 Deploying {name}...")
    with open(config_file, 'r') as f:
        config = json.load(f)
    
    config_json = json.dumps(config)
    cmd = f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -X POST http://localhost:8083/connectors -H 'Content-Type: application/json' -d '{config_json}'"
    output, code = run(cmd)
    
    if code == 0:
        print(f"✅ {name} deployed")
    else:
        print(f"⚠️ {name} failed: {output}")
    return code == 0

def check_connectors():
    print("\n🔍 Checking connector status...")
    output, _ = run(f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -s http://localhost:8083/connectors")
    try:
        connectors = json.loads(output)
        print(f"📋 Active connectors: {', '.join(connectors) if connectors else 'None'}")
    except:
        print(f"⚠️ Could not parse connectors: {output}")

# Wait for Kafka Connect to be ready
print("⏳ Waiting for Kafka Connect REST API...")
for i in range(30):
    output, code = run(f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -s http://localhost:8083/")
    if code == 0 and "version" in output:
        print("✅ Kafka Connect is ready")
        break
    time.sleep(2)
else:
    print("⚠️ Kafka Connect may not be ready, continuing anyway...")

# Deploy connectors
deploy_connector("configs/postgres-source-connector.json", "PostgreSQL Source Connector")
time.sleep(2)
deploy_connector("configs/iceberg-bronze-s3-sink-connector.json", "Iceberg Bronze S3 Sink Connector")
time.sleep(2)
deploy_connector("configs/ifood-iceberg-s3-tables-connector.json", "iFood Iceberg S3 Tables Connector")

# Deploy SQL Server connector via kubectl
print("📦 Deploying SQL Server Source Connector...")
output, code = run("kubectl apply -f sqlserver-connector.yaml")
if code == 0:
    print("✅ SQL Server Source Connector deployed")
else:
    print(f"⚠️ SQL Server Source Connector failed: {output}")

# Check status
time.sleep(2)
check_connectors()
