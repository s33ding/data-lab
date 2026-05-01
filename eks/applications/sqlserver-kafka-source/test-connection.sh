#!/bin/bash
HOST="funasadb.dataiesb.com"
PORT=1433

echo "Testing DNS resolution..."
nslookup "$HOST" || { echo "DNS resolution failed"; exit 1; }

echo -e "\nTesting TCP connection on port $PORT..."
timeout 5 bash -c "echo > /dev/tcp/$HOST/$PORT" 2>/dev/null \
  && echo "TCP connection successful" \
  || { echo "TCP connection failed"; exit 1; }

echo -e "\nTesting SQL Server login..."
SA_PASSWORD=$(kubectl get secret sqlserver-secret -n default -o jsonpath='{.data.SA_PASSWORD}' | base64 -d)
sqlcmd -S "$HOST,$PORT" -U SA -P "$SA_PASSWORD" -Q "SELECT @@VERSION" -C 2>&1 \
  && echo "SQL Server connection successful" \
  || echo "SQL Server login failed (sqlcmd may not be installed)"
