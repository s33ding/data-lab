# Kafka Playground API

Simple REST API for ingesting data to and from Kafka.

## Endpoints

### POST /messages
Send data to Kafka topic.

**Request:**
```json
{
  "topic": "playground-topic",
  "key": "optional-key",
  "message": {"your": "data"}
}
```

**Response:**
```json
{"status": "sent", "topic": "playground-topic"}
```

### GET /messages
Retrieve consumed messages from Kafka.

**Query Parameters:**
- `limit` (optional): Number of messages to return (default: 10)

**Response:**
```json
[
  {
    "timestamp": "2026-01-31T22:02:49.547526",
    "topic": "playground-topic", 
    "key": null,
    "value": {"test": "data"}
  }
]
```

### GET /health
Health check endpoint.

**Response:**
```json
{"status": "ok"}
```

## Usage Examples

```bash
# Send message
curl -X POST http://lab.dataiesb.com/messages \
  -H "Content-Type: application/json" \
  -d '{"message": {"user": "test", "data": "hello"}}'

# Get messages
curl http://lab.dataiesb.com/messages?limit=5

# Health check
curl http://lab.dataiesb.com/health
```

## Test Scripts

- `./test-api.sh` - Basic API functionality test
- `./batch-test.sh` - Send multiple messages for load testing

## Deployment

```bash
# Build and push image
./build-push.sh

# Deploy to Kubernetes
kubectl apply -f deployment.yaml
```
