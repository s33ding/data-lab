#!/usr/bin/env python3
"""Add the Bitnami Helm repo and update."""
import subprocess, sys

def run(cmd):
    print(f"$ {cmd}")
    r = subprocess.run(cmd, shell=True)
    if r.returncode != 0:
        sys.exit(r.returncode)

run("helm repo add bitnami https://charts.bitnami.com/bitnami")
run("helm repo update bitnami")
print("\n✅ Bitnami repo ready")
