#!/usr/bin/env python3
import subprocess
import json
import sys
from config import POD_NAME, NAMESPACE, CONNECT_URL

def delete_connector(connector_name):
    cmd = f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -X DELETE {CONNECT_URL}/connectors/{connector_name}"
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        print(f"✅ Deleted: {connector_name}")
    else:
        print(f"⚠️ Failed to delete: {connector_name}")

def delete_all():
    cmd = f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -s {CONNECT_URL}/connectors"
    output = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    connectors = json.loads(output.stdout)
    for conn in connectors:
        delete_connector(conn)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        delete_connector(sys.argv[1])
    else:
        delete_all()
