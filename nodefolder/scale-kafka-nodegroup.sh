#!/bin/bash

CLUSTER_NAME="sas-6881323-eks"
DESIRED_SIZE="${1}"

if [ -z "$DESIRED_SIZE" ]; then
  echo "Usage: $0 <desired-size>"
  echo "Example: $0 1"
  exit 1
fi

if [ "$DESIRED_SIZE" -lt 0 ] || [ "$DESIRED_SIZE" -gt 1 ]; then
  echo "Error: desired-size must be 0 or 1"
  exit 1
fi

MAX_SIZE=1
if [ "$DESIRED_SIZE" -eq 0 ]; then
  MAX_SIZE=1
else
  MAX_SIZE="$DESIRED_SIZE"
fi

aws eks update-nodegroup-config \
  --cluster-name "$CLUSTER_NAME" \
  --nodegroup-name kafka-managed-nodes \
  --scaling-config minSize="$DESIRED_SIZE",maxSize="$MAX_SIZE",desiredSize="$DESIRED_SIZE"
