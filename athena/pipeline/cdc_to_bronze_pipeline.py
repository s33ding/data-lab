import json
import boto3
import hashlib
from kafka import KafkaConsumer
from datetime import datetime

# Kafka consumer setup
consumer = KafkaConsumer(
    'mcdonalds_sales',  # Your CDC topic
    bootstrap_servers=['localhost:9092'],  # Adjust as needed
    value_deserializer=lambda x: json.loads(x.decode('utf-8')),
    auto_offset_reset='earliest'
)

# S3 client for writing to bronze layer
s3_client = boto3.client('s3', region_name='us-east-1')
bucket = 's33ding-kafka-output'
bronze_prefix = 'db_bronze/mcdonalds_sales/'

def write_to_bronze(records):
    """Write CDC records to bronze S3 location in Parquet format"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    filename = f"{bronze_prefix}cdc_batch_{timestamp}.json"
    
    # Convert records to JSON lines format
    json_data = '\n'.join([json.dumps(record) for record in records])
    
    s3_client.put_object(
        Bucket=bucket,
        Key=filename,
        Body=json_data.encode('utf-8')
    )
    print(f"Written {len(records)} records to {filename}")

# Process CDC messages
batch = []
batch_size = 100

print("Starting CDC to Bronze pipeline...")

for message in consumer:
    cdc_record = message.value
    
    # Create record hash for deduplication
    record_str = json.dumps(cdc_record, sort_keys=True)
    record_hash = hashlib.md5(record_str.encode()).hexdigest()
    
    # Structure for bronze table
    bronze_record = {
        'op': cdc_record.get('op', ''),
        'ts_ms': cdc_record.get('ts_ms', 0),
        'before': json.dumps(cdc_record.get('before')) if cdc_record.get('before') else None,
        'after': json.dumps(cdc_record.get('after')) if cdc_record.get('after') else None,
        'record_hash': record_hash
    }
    
    batch.append(bronze_record)
    
    # Write batch when full
    if len(batch) >= batch_size:
        write_to_bronze(batch)
        batch = []

consumer.close()
