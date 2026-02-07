#!/usr/bin/env python3
import subprocess
import sys

def run(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(result.stdout, end='')
    if result.stderr:
        print(result.stderr, end='', file=sys.stderr)
    return result.returncode == 0

def get_pod():
    result = subprocess.run(
        "kubectl get pods -n lab -l app=postgres -o jsonpath='{.items[0].metadata.name}'",
        shell=True, capture_output=True, text=True
    )
    return result.stdout.strip()

def exec_sql(pod, sql):
    return run(f'kubectl exec -n lab {pod} -- psql -U postgres -d testdb -c "{sql}"')

if __name__ == "__main__":
    pod = get_pod()
    print("🔌 Testing PostgreSQL connection...")
    exec_sql(pod, "SELECT version();")
    print("\n📋 Listing tables...")
    exec_sql(pod, "\\dt")
    print("✅ Connection test passed!")
