#!/usr/bin/env python3
"""Uninstall Spark from EKS."""
import subprocess, sys, os

DIR = os.path.dirname(os.path.abspath(__file__))
NS = "default"

def run(cmd, check=True):
    print(f"$ {cmd}")
    r = subprocess.run(cmd, shell=True)
    if check and r.returncode != 0:
        sys.exit(r.returncode)

print("🗑️  Uninstalling Spark...")
run(f"helm uninstall spark -n {NS}", check=False)

print("🗑️  Removing PVC...")
run(f"kubectl delete -f {DIR}/pvc.yaml", check=False)

print("\n✅ Spark removed")
