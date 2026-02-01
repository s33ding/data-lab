#!/bin/bash

# List topics
kubectl exec -n lab kafka-brokers-0 -- kafka-topics \
    --list \
    --bootstrap-server kafka-brokers:9092
