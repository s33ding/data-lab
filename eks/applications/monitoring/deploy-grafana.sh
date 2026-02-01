#!/bin/bash

echo "🚀 Deploying Grafana..."
kubectl apply -f grafana.yaml

echo "⏳ Waiting for Grafana to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n lab

echo "🔗 Port forwarding Grafana (admin/admin)..."
kubectl port-forward svc/grafana 3000:3000 -n lab
