#!/bin/bash
set -e

POD=$(kubectl get pods -n lab -l app=postgres -o jsonpath='{.items[0].metadata.name}')

echo "🍔 Testing McDonald's tables..."
kubectl exec -n lab $POD -- psql -U postgres -d testdb -c "\dt kafka.*"

echo "📊 Table counts:"
kubectl exec -n lab $POD -- psql -U postgres -d testdb -c "
SELECT 'mcdonalds_sales' as table_name, COUNT(*) FROM kafka.mcdonalds_sales
UNION ALL SELECT 'mcdonalds_inventory', COUNT(*) FROM kafka.mcdonalds_inventory
UNION ALL SELECT 'mcdonalds_employees', COUNT(*) FROM kafka.mcdonalds_employees;"

echo "✅ McDonald's tables ready!"
