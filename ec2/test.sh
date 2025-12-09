#!/bin/bash

echo "Testing Kafka CDC Pipeline..."

# Change to Kafka directory
cd /root/kafka_2.13-3.0.0

echo "=== 1. Testing Kafka Server ==="
bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
echo ""

echo "=== 2. Testing Kafka Connect ==="
curl -s http://localhost:8083/ | jq '.' || curl -s http://localhost:8083/
echo ""

echo "=== 3. Checking Connectors ==="
echo "Active connectors:"
curl -s http://localhost:8083/connectors
echo ""

echo "Debezium connector status:"
curl -s http://localhost:8083/connectors/postgres-debezium-connector/status | jq '.' 2>/dev/null || curl -s http://localhost:8083/connectors/postgres-debezium-connector/status
echo ""

echo "S3 sink connector status:"
curl -s http://localhost:8083/connectors/s3-sink-debezium/status | jq '.' 2>/dev/null || curl -s http://localhost:8083/connectors/s3-sink-debezium/status
echo ""

echo "=== 4. Testing Database Connection ==="
python3 -c "
import boto3
import json
import psycopg2

# Get credentials
client = boto3.client('secretsmanager', region_name='us-east-1')
response = client.get_secret_value(SecretId='rds-master')
creds = json.loads(response['SecretString'])

try:
    conn = psycopg2.connect(
        host=creds['host'],
        database=creds['db_name'],
        user=creds['username'],
        password=creds['password'],
        port=5432
    )
    cursor = conn.cursor()
    cursor.execute('SELECT COUNT(*) FROM kafka.mcdonalds_sales;')
    count = cursor.fetchone()[0]
    print(f'Current records in table: {count}')
    conn.close()
    print('Database connection: OK')
except Exception as e:
    print(f'Database connection failed: {e}')
"
echo ""

echo "=== 5. Inserting Test Data ==="
python3 -c "
import boto3
import json
import psycopg2
import uuid
from datetime import datetime

# Get credentials
client = boto3.client('secretsmanager', region_name='us-east-1')
response = client.get_secret_value(SecretId='rds-master')
creds = json.loads(response['SecretString'])

try:
    conn = psycopg2.connect(
        host=creds['host'],
        database=creds['db_name'],
        user=creds['username'],
        password=creds['password'],
        port=5432
    )
    cursor = conn.cursor()
    
    # Insert test record
    test_id = str(uuid.uuid4())[:8]
    cursor.execute('''
        INSERT INTO kafka.mcdonalds_sales 
        (store_id, store_name, transaction_id, product_code, product_name, 
         category, quantity, unit_price, total_amount, payment_method, region, city) 
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
    ''', (
        999, f'Test Store {test_id}', f'TEST_{test_id}', 'TEST001', 
        'Test Product', 'Test', 1, 10.00, 10.00, 'test', 'Test Region', 'Test City'
    ))
    
    conn.commit()
    print(f'Inserted test record with ID: TEST_{test_id}')
    conn.close()
except Exception as e:
    print(f'Failed to insert test data: {e}')
"
echo ""

echo "=== 6. Checking Kafka Topics ==="
echo "Available topics:"
bin/kafka-topics.sh --bootstrap-server localhost:9092 --list
echo ""

echo "Checking for CDC messages (last 5 messages):"
timeout 10s bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic iesb-postgres.kafka.mcdonalds_sales \
  --from-beginning \
  --max-messages 5 2>/dev/null || echo "No messages found or topic doesn't exist"
echo ""

echo "=== 7. Checking S3 Bucket ==="
aws s3 ls s3://s33ding-kafka-output/topics/ 2>/dev/null && echo "S3 files found!" || echo "No S3 files yet (may take a few minutes)"
echo ""

echo "=== Test Complete ==="
echo "If everything is working:"
echo "1. Database connection should be OK"
echo "2. Test record should be inserted"
echo "3. CDC messages should appear in Kafka topic"
echo "4. Files should eventually appear in S3 bucket"
