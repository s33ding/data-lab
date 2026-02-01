import json
import boto3
from kafka import KafkaConsumer
from datetime import datetime
import os

# AWS S3 client
s3_client = boto3.client('s3', region_name='sa-east-1')
bucket_name = 's33ding-kafka-output'

# Kafka consumer
consumer = KafkaConsumer(
    'playground-topic',
    bootstrap_servers=['kafka-brokers:9092'],
    value_deserializer=lambda m: json.loads(m.decode('utf-8')),
    auto_offset_reset='earliest',
    group_id='s3-sink-consumer'
)

print(f"Starting S3 sink consumer for topic: playground-topic")
print(f"Writing to S3 bucket: {bucket_name}")

for message in consumer:
    try:
        # Create S3 key with timestamp and partition info
        timestamp = datetime.now().strftime('%Y/%m/%d/%H')
        key = f"kafka-data/{timestamp}/partition-{message.partition}/offset-{message.offset}.json"
        
        # Prepare data for S3
        data = {
            'timestamp': datetime.now().isoformat(),
            'topic': message.topic,
            'partition': message.partition,
            'offset': message.offset,
            'key': message.key.decode('utf-8') if message.key else None,
            'value': message.value
        }
        
        # Write to S3
        s3_client.put_object(
            Bucket=bucket_name,
            Key=key,
            Body=json.dumps(data),
            ContentType='application/json'
        )
        
        print(f"✅ Message written to S3: s3://{bucket_name}/{key}")
        
    except Exception as e:
        print(f"❌ Error writing to S3: {e}")
