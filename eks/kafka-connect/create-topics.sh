#!/bin/bash

# Create sink topic for McDonald's sales data
kubectl exec -n lab kafka-brokers-0 -- kafka-topics \
    --create \
    --bootstrap-server kafka-brokers:9092 \
    --topic sink-postgres-server.kafka.mcdonalds_sales \
    --partitions 3 \
    --replication-factor 3
