#!/bin/bash

# Create topic for postgres connection (using actual topic prefix)
kubectl exec -n lab kafka-brokers-0 -- kafka-topics \
    --create \
    --bootstrap-server kafka-brokers:9092 \
    --topic postgres-server.public.users \
    --partitions 3 \
    --replication-factor 3
