#!/usr/bin/env python3
"""Upgrade Spark on EKS with latest values."""
import subprocess, sys, os

DIR = os.path.dirname(os.path.abspath(__file__))
NS = "default"

def run(cmd):
    print(f"$ {cmd}")
    r = subprocess.run(cmd, shell=True)
    if r.returncode != 0:
        sys.exit(r.returncode)

print("⬆️  Upgrading Spark...")
run(f"helm upgrade spark bitnami/spark -f {DIR}/values.yaml -n {NS}")

print("⏳ Waiting for rollout...")
run(f"kubectl rollout status statefulset/spark-master -n {NS} --timeout=300s")
run(f"kubectl rollout status statefulset/spark-worker -n {NS} --timeout=300s")

print("\n✅ Spark upgraded")
