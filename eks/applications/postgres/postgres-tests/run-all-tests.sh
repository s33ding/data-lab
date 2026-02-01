#!/bin/bash
set -e

echo "🧪 Running PostgreSQL Integration Tests..."

# Run all tests in sequence
./test-connection.sh
echo ""
./query-data.sh
echo ""
./insert-test-data.sh
echo ""

# Test Kafka integration
echo "📡 Testing Kafka integration..."
kubectl exec -n lab kafka-brokers-0 -- kafka-console-consumer \
    --bootstrap-server kafka-brokers:9092 \
    --topic postgres-server.public.users \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 5000

echo ""
echo "✅ All PostgreSQL tests completed!"
