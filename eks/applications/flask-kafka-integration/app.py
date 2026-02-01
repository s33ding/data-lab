from flask import Flask, request, jsonify
import json
from kafka import KafkaProducer, KafkaConsumer
import threading
from datetime import datetime

app = Flask(__name__)

# Kafka configuration
KAFKA_SERVERS = ['kafka-brokers:9092']
DEFAULT_TOPIC = 'playground-topic'

# Store consumed messages
consumed_messages = []

# Initialize producer
producer = None

def get_producer():
    global producer
    if producer is None:
        producer = KafkaProducer(
            bootstrap_servers=KAFKA_SERVERS,
            value_serializer=lambda v: json.dumps(v).encode('utf-8'),
            key_serializer=lambda k: k.encode('utf-8') if k else None
        )
    return producer

# Consumer thread
def consume_messages():
    consumer = KafkaConsumer(
        DEFAULT_TOPIC,
        bootstrap_servers=KAFKA_SERVERS,
        value_deserializer=lambda m: json.loads(m.decode('utf-8')),
        auto_offset_reset='latest',
        group_id='api-consumer'
    )
    
    for message in consumer:
        consumed_messages.append({
            'timestamp': datetime.now().isoformat(),
            'topic': message.topic,
            'key': message.key.decode('utf-8') if message.key else None,
            'value': message.value
        })
        if len(consumed_messages) > 100:
            consumed_messages.pop(0)

# Start consumer thread
threading.Thread(target=consume_messages, daemon=True).start()

@app.route('/messages', methods=['POST'])
def send_message():
    data = request.json
    topic = data.get('topic', DEFAULT_TOPIC)
    key = data.get('key')
    message = data.get('message')
    
    producer = get_producer()
    producer.send(topic, value=message, key=key)
    producer.flush()
    
    return jsonify({'status': 'sent', 'topic': topic})

@app.route('/messages', methods=['GET'])
def get_messages():
    limit = request.args.get('limit', 10, type=int)
    return jsonify(consumed_messages[-limit:])

@app.route('/health')
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
