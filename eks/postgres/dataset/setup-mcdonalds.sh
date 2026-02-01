#!/bin/bash

# Setup McDonald's table in cluster PostgreSQL
echo "Setting up port forward..."
kubectl port-forward -n lab postgres-559bd79b84-7cqtg 5433:5432 &
PF_PID=$!

sleep 3

echo "Creating kafka schema and mcdonalds_sales table..."
python3 postgres_setup.py

echo "Killing port forward..."
kill $PF_PID

echo "Setup complete!"
