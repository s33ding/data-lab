#!/bin/bash

echo "=== Testing PostgreSQL → Kafka → S3 Integration ==="

# 1. Insert test data into PostgreSQL
echo "1. Inserting test data into PostgreSQL..."
kubectl exec -n lab postgres-559bd79b84-7cqtg -- psql -U postgres -d mydb -c "
INSERT INTO users (name, email) VALUES ('Test User', 'test@example.com');
INSERT INTO orders (user_id, total) VALUES (1, 99.99);
INSERT INTO products (name, price) VALUES ('Test Product', 29.99);
INSERT INTO transactions (order_id, amount) VALUES (1, 99.99);
"

# 2. Check Kafka topics for data
echo "2. Checking Kafka topics..."
kubectl exec -n lab kafka-brokers-0 -- kafka-console-consumer \
    --bootstrap-server kafka-brokers:9092 \
    --topic postgres-server.public.users \
    --from-beginning \
    --max-messages 1 \
    --timeout-ms 10000

# 3. Check connector status
echo "3. Checking connector status..."
kubectl exec -n lab kafka-connect-proper-0 -- curl -s http://localhost:8083/connectors/postgres-source-connector/status | jq .

echo "=== Integration test complete ==="
