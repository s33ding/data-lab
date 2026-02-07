#!/usr/bin/env python3
import subprocess
import json
from config import POD_NAME, NAMESPACE, CONNECT_URL

output = subprocess.run(
    f"kubectl exec -n {NAMESPACE} {POD_NAME} -- curl -s {CONNECT_URL}/connectors",
    shell=True, capture_output=True, text=True
)
print(json.dumps(json.loads(output.stdout), indent=2))
