#!/bin/bash

POD_NAME="kafka-connect-0"
CONNECT_URL="http://localhost:8083"

kubectl exec $POD_NAME -c kafka-connect -- curl -s http://localhost:8083/connectors
echo
