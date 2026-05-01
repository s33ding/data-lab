#!/bin/bash

echo "Creating namespace..."
kubectl create namespace funasa --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying SQL Server..."
kubectl apply -f sqlserver-secret.yaml
kubectl apply -f sqlserver-init.yaml
kubectl apply -f sqlserver-deployment.yaml

echo "Waiting for SQL Server to be ready..."
kubectl wait --for=condition=ready pod -l app=sqlserver -n funasa --timeout=300s

echo "SQL Server deployed successfully!"

echo "Inserting iFood data..."
python3 ifood_insert.py

echo "Waiting for NLB endpoint..."
NLB=""
while [ -z "$NLB" ]; do
  NLB=$(kubectl get svc sqlserver-service -n funasa -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  [ -z "$NLB" ] && sleep 5
done

echo "Connection details:"
echo "  Host: $NLB"
echo "  Port: 1433"
echo "  Database: TestDB / FunasaDB"
echo "  Username: sa"
echo "  Password: (from sqlserver-secret)"
