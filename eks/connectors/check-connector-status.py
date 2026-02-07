#!/usr/bin/env python3
import subprocess
import json
import sys
from config import POD_NAME, NAMESPACE, CONNECT_URL

def get_status(connector=None):
    if connector:
        cmd = f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -s {CONNECT_URL}/connectors/{connector}/status"
        output = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        print(json.dumps(json.loads(output.stdout), indent=2))
    else:
        cmd = f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -s {CONNECT_URL}/connectors"
        output = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        connectors = json.loads(output.stdout)
        for conn in connectors:
            print(f"\n=== {conn} ===")
            cmd = f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -s {CONNECT_URL}/connectors/{conn}/status"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            print(json.dumps(json.loads(result.stdout), indent=2))

if __name__ == "__main__":
    get_status(sys.argv[1] if len(sys.argv) > 1 else None)
