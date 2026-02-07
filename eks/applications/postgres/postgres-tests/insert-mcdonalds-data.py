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
    print("➕ Inserting McDonald's test data...")
    
    exec_sql(pod, """
        INSERT INTO kafka.mcdonalds_sales (store_id, store_name, transaction_id, product_code, product_name, category, quantity, unit_price, total_amount, payment_method, region, city)
        VALUES (1, 'McDonalds Store 1', 'TXN001', 'BIG001', 'Big Mac', 'Burgers', 2, 15.90, 31.80, 'credit_card', 'Southeast', 'São Paulo');
    """)
    
    exec_sql(pod, """
        INSERT INTO kafka.mcdonalds_inventory (store_id, product_code, product_name, current_stock, min_stock, max_stock, last_restock_date)
        VALUES (1, 'BIG001', 'Big Mac', 50, 20, 100, NOW());
    """)
    
    exec_sql(pod, """
        INSERT INTO kafka.mcdonalds_employees (store_id, employee_id, name, position, hire_date, shift, hourly_rate)
        VALUES (1, 'EMP001', 'John Doe', 'Cashier', '2024-01-01', 'morning', 18.50);
    """)
    
    print("✅ Test data inserted!")
