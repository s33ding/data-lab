#!/bin/bash

# Consume messages
kubectl exec -n lab kafka-brokers-0 -- kafka-console-consumer \
    --bootstrap-server kafka-brokers:9092 \
    --topic postgres.public.users \
    --from-beginning
