#!/bin/bash

# Cleanup McDonald's setup
echo "Setting up port forward..."
kubectl port-forward -n lab postgres-559bd79b84-7cqtg 5433:5432 &
PF_PID=$!

sleep 3

echo "Dropping kafka schema and table..."
PGPASSWORD=postgres psql -h localhost -p 5433 -U postgres -d testdb -c "DROP SCHEMA IF EXISTS kafka CASCADE;"

echo "Killing port forward..."
kill $PF_PID

echo "Cleanup complete!"
