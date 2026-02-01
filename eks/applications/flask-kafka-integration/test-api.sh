#!/bin/bash

API_URL="http://lab.dataiesb.com"

echo "Testing Kafka API..."

# Test health
echo "1. Health check:"
curl -s "$API_URL/health" | jq .

# Send message
echo -e "\n2. Sending message:"
curl -X POST "$API_URL/messages" \
  -H "Content-Type: application/json" \
  -d '{"message": {"user": "test", "action": "demo", "timestamp": "'$(date -Iseconds)'"}}' | jq .

# Wait and get messages
echo -e "\n3. Retrieving messages:"
sleep 2
curl -s "$API_URL/messages?limit=5" | jq .
