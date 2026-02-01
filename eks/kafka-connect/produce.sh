#!/bin/bash

# Produce messages
kubectl exec -it -n lab kafka-brokers-0 -- kafka-console-producer \
    --bootstrap-server kafka-brokers:9092 \
    --topic postgres.public.users
