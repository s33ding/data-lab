#!/usr/bin/env python3
"""Install Spark on EKS using Bitnami Helm chart with custom ECR image."""
import subprocess, sys, os

DIR = os.path.dirname(os.path.abspath(__file__))
NS = "default"

def run(cmd):
    print(f"$ {cmd}")
    r = subprocess.run(cmd, shell=True)
    if r.returncode != 0:
        sys.exit(r.returncode)

print("📦 Creating PVC...")
run(f"kubectl apply -f {DIR}/pvc.yaml")

print("⚡ Installing Spark...")
run(f"helm upgrade --install spark bitnami/spark -f {DIR}/values.yaml -n {NS}")

print("⏳ Waiting for Spark master...")
run(f"kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=master,app.kubernetes.io/name=spark -n {NS} --timeout=300s")

print("⏳ Waiting for Spark workers...")
run(f"kubectl wait --for=condition=ready pod -l app.kubernetes.io/component=worker,app.kubernetes.io/name=spark -n {NS} --timeout=300s")

print("\n✅ Spark deployed!")
print(f"  Master UI:  kubectl port-forward svc/spark-master-svc 8080:80 -n {NS}")
print(f"  Master URL: spark://spark-master-svc.{NS}.svc.cluster.local:7077")
print(f"  Trino:      trino.trino.svc.cluster.local:8080")
