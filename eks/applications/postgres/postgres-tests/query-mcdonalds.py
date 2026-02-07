#!/usr/bin/env python3
import subprocess

def run(cmd):
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    print(result.stdout, end='')
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
    print("📊 Querying McDonald's data...")
    
    print("\n🍔 Sales:")
    exec_sql(pod, "SELECT * FROM kafka.mcdonalds_sales LIMIT 5;")
    
    print("\n📦 Inventory:")
    exec_sql(pod, "SELECT * FROM kafka.mcdonalds_inventory LIMIT 5;")
    
    print("\n👥 Employees:")
    exec_sql(pod, "SELECT * FROM kafka.mcdonalds_employees LIMIT 5;")
