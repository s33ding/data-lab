#!/bin/bash

POD_NAME="kafka-connect-proper-0"
CONNECT_URL="http://localhost:8083"

if [ $# -eq 0 ]; then
    echo "Checking all connector statuses..."
    for connector in $(kubectl exec $POD_NAME -- curl -s $CONNECT_URL/connectors | jq -r '.[]'); do
        echo "Status for $connector:"
        kubectl exec $POD_NAME -- curl -s $CONNECT_URL/connectors/$connector/status | jq
        echo
    done
else
    echo "Checking status for connector: $1"
    kubectl exec $POD_NAME -- curl -s $CONNECT_URL/connectors/$1/status | jq
fi
