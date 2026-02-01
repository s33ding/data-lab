#!/bin/bash
set -e

echo "🐘 Starting PostgreSQL port forward and psql connection..."

# Kill existing postgres port forward
pkill -f "kubectl port-forward.*postgres" 2>/dev/null || true

# Start port forward in background
kubectl port-forward svc/postgres-service 5432:5432 &
PF_PID=$!

# Wait for port forward to be ready
sleep 2

echo "📡 PostgreSQL available at localhost:5432"
echo "🔗 Connecting with psql..."

# Connect with psql
psql -h localhost -p 5432 -U postgres -d testdb

# Cleanup on exit
trap "kill $PF_PID 2>/dev/null || true" EXIT
