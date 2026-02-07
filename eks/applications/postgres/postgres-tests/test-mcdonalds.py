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
    print("🍔 Testing McDonald's tables...")
    exec_sql(pod, "\\dt kafka.*")
    
    print("\n📊 Table counts:")
    exec_sql(pod, """
        SELECT 'mcdonalds_sales' as table_name, COUNT(*) FROM kafka.mcdonalds_sales
        UNION ALL SELECT 'mcdonalds_inventory', COUNT(*) FROM kafka.mcdonalds_inventory
        UNION ALL SELECT 'mcdonalds_employees', COUNT(*) FROM kafka.mcdonalds_employees;
    """)
    print("✅ McDonald's tables ready!")
