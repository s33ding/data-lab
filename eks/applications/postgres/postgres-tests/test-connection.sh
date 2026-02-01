#!/bin/bash
set -e

POSTGRES_POD=$(kubectl get pods -n lab -l app=postgres -o jsonpath='{.items[0].metadata.name}')

echo "🔌 Testing PostgreSQL connection..."
kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -c "SELECT version();"

echo "📋 Listing tables..."
kubectl exec -n lab $POSTGRES_POD -- psql -U postgres -d testdb -c "\dt"

echo "✅ Connection test passed!"
