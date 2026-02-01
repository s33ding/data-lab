#!/bin/bash
set -e

POSTGRES_POD=$(kubectl get pods -n lab -l app=postgres -o jsonpath='{.items[0].metadata.name}')

echo "➕ Inserting test data..."

kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -c "
INSERT INTO users (name, email) VALUES 
    ('Test User $(date +%s)', 'test$(date +%s)@example.com');

INSERT INTO orders (user_id, product, amount) VALUES 
    ((SELECT id FROM users ORDER BY id DESC LIMIT 1), 
     'Test Product $(date +%s)', 
     $(shuf -i 10-100 -n 1).99);
"

echo "✅ Test data inserted successfully!"
echo "📊 Current counts:"
kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -c "
SELECT 
    'users' as table_name, COUNT(*) as count FROM users
UNION ALL SELECT 
    'orders', COUNT(*) FROM orders;
"
