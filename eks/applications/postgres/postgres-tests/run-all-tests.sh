#!/bin/bash
set -e

echo "🧪 Running PostgreSQL Integration Tests..."

./test-connection.sh
echo ""
./test-mcdonalds.sh
echo ""
./insert-mcdonalds-data.sh
echo ""
./query-mcdonalds.sh

echo ""
echo "✅ All PostgreSQL tests completed!"
