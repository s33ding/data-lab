#!/bin/bash
set -e

POSTGRES_POD=$(kubectl get pods -n lab -l app=postgres -o jsonpath='{.items[0].metadata.name}')

echo "📊 Querying all tables..."

echo "👥 Users ($(kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -t -c "SELECT COUNT(*) FROM users;")):"
kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -c "SELECT * FROM users LIMIT 5;"

echo "📦 Orders ($(kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -t -c "SELECT COUNT(*) FROM orders;")):"
kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -c "SELECT * FROM orders LIMIT 5;"

echo "📋 Schema info:"
kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -c "\d orders"
