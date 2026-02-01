#!/bin/bash

POD_NAME="kafka-connect-proper-0"
CONNECT_URL="http://localhost:8083"

kubectl exec $POD_NAME -c kafka-connect-proper -- curl -s http://localhost:8083/connectors
echo
