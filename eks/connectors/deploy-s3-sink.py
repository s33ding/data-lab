#!/usr/bin/env python3
import subprocess
import json
from config import POD_NAME, NAMESPACE, CONNECT_URL

with open("configs/playground-s3-sink-connector.json") as f:
    config = json.load(f)

cmd = f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -X POST {CONNECT_URL}/connectors -H 'Content-Type: application/json' -d '{json.dumps(config)}'"
subprocess.run(cmd, shell=True)
print("\n✅ Playground S3 Sink Connector created!")
