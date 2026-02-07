#!/bin/bash
set -e

POD=$(kubectl get pods -n lab -l app=postgres -o jsonpath='{.items[0].metadata.name}')

echo "📊 Querying McDonald's data..."

echo -e "\n🍔 Sales:"
kubectl exec -n lab $POD -- psql -U postgres -d testdb -c "SELECT * FROM kafka.mcdonalds_sales LIMIT 5;"

echo -e "\n📦 Inventory:"
kubectl exec -n lab $POD -- psql -U postgres -d testdb -c "SELECT * FROM kafka.mcdonalds_inventory LIMIT 5;"

echo -e "\n👥 Employees:"
kubectl exec -n lab $POD -- psql -U postgres -d testdb -c "SELECT * FROM kafka.mcdonalds_employees LIMIT 5;"
