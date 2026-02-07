#!/bin/bash
set -e

POD=$(kubectl get pods -n lab -l app=postgres -o jsonpath='{.items[0].metadata.name}')

echo "➕ Inserting McDonald's test data..."

kubectl exec -n lab $POD -- psql -U postgres -d testdb -c "
INSERT INTO kafka.mcdonalds_sales (store_id, store_name, transaction_id, product_code, product_name, category, quantity, unit_price, total_amount, payment_method, region, city)
VALUES (1, 'McDonalds Store 1', 'TXN001', 'BIG001', 'Big Mac', 'Burgers', 2, 15.90, 31.80, 'credit_card', 'Southeast', 'São Paulo');

INSERT INTO kafka.mcdonalds_inventory (store_id, product_code, product_name, current_stock, min_stock, max_stock, last_restock_date)
VALUES (1, 'BIG001', 'Big Mac', 50, 20, 100, NOW());

INSERT INTO kafka.mcdonalds_employees (store_id, employee_id, name, position, hire_date, shift, hourly_rate)
VALUES (1, 'EMP001', 'John Doe', 'Cashier', '2024-01-01', 'morning', 18.50);
"

echo "✅ Test data inserted!"
