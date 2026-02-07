#!/usr/bin/env python3
import subprocess
import sys
import time
import json

def run(cmd, check=False, capture=False):
    """Run command"""
    result = subprocess.run(cmd, shell=True, capture_output=capture, text=True)
    if check and result.returncode != 0:
        print(f"⚠️ Command failed: {cmd}")
    return result

def safe_delete(resource_type, resource_name, namespace="lab"):
    """Delete resource if it exists"""
    check = run(f"kubectl get {resource_type} {resource_name} -n {namespace}", capture=True)
    if check.returncode == 0:
        print(f"🔄 Deleting {resource_type}/{resource_name}")
        run(f"kubectl delete {resource_type} {resource_name} -n {namespace} --timeout=60s", check=True)
    else:
        print(f"⚠️ {resource_type}/{resource_name} not found")

def delete_connectors(namespace="lab"):
    """Delete all Kafka connectors"""
    print("🔄 Deleting Kafka connectors...")
    pod_result = run("kubectl get pods -l app=kafka-connect -o jsonpath='{.items[0].metadata.name}' -n lab", capture=True)
    if pod_result.returncode != 0 or not pod_result.stdout.strip("'"):
        print("⚠️ Kafka Connect pod not found")
        return
    
    pod = pod_result.stdout.strip("'")
    connectors_result = run(f"kubectl exec -n {namespace} {pod} -- curl -s http://localhost:8083/connectors", capture=True)
    if connectors_result.returncode == 0:
        try:
            connectors = json.loads(connectors_result.stdout)
            for connector in connectors:
                print(f"🔄 Deleting connector: {connector}")
                run(f"kubectl exec -n {namespace} {pod} -- curl -X DELETE http://localhost:8083/connectors/{connector}", check=True)
        except:
            print("⚠️ No connectors found")

print("🗑️ Starting Kafka EKS cleanup...")

namespace = "lab"
if run(f"kubectl get namespace {namespace}", capture=True).returncode != 0:
    print("⚠️ Lab namespace doesn't exist")
    namespace = "default"

delete_connectors(namespace)

print("🔄 Deleting applications...")
safe_delete("deployment", "flask-kafka-integration", namespace)
safe_delete("service", "flask-kafka-integration", namespace)
safe_delete("deployment", "kafka-playground", namespace)
safe_delete("service", "kafka-playground-service", namespace)

print("🔄 Deleting monitoring...")
safe_delete("deployment", "kafka-ui", namespace)
safe_delete("service", "kafka-ui", namespace)
safe_delete("deployment", "grafana", namespace)
safe_delete("service", "grafana", namespace)

print("🔄 Deleting Kafka Connect...")
safe_delete("kafkaconnect", "kafka-connect", namespace)
safe_delete("service", "kafka-connect", namespace)

print("🔄 Deleting PostgreSQL...")
safe_delete("deployment", "postgres", namespace)
safe_delete("service", "postgres", namespace)
safe_delete("pvc", "postgres-pvc", namespace)

print("🔄 Deleting Kafka infrastructure...")
run(f"kubectl delete connector --all -n {namespace} --force --grace-period=0", check=True)
safe_delete("kafka", "kafka-brokers", namespace)
safe_delete("kraftcontroller", "kraftcontroller", namespace)
safe_delete("kraftcontroller", "kraft-controller", namespace)

print("🔄 Deleting PVCs...")
run(f"kubectl delete pvc --all -n {namespace} --force --grace-period=0 --timeout=10s 2>/dev/null", check=False)

helm_check = run(f"helm list -n {namespace}", capture=True)
if helm_check.returncode == 0 and "confluent-operator" in helm_check.stdout:
    print("🔄 Uninstalling Confluent Operator...")
    run(f"helm uninstall confluent-operator -n {namespace}", check=True)

print("🔄 Cleaning up persistent volumes...")
run(f"kubectl get pv | grep {namespace} | awk '{{print $1}}' | xargs -r kubectl delete pv --timeout=10s 2>/dev/null", check=False)

if namespace == "lab":
    response = input("Delete 'lab' namespace? (y/N): ").lower()
    if response == 'y':
        print("🔄 Deleting lab namespace...")
        if run(f"kubectl delete namespace lab --timeout=120s").returncode != 0:
            print("⚠️ Removing finalizers...")
            run("kubectl get namespace lab -o json | jq '.spec.finalizers = []' | kubectl replace --raw /api/v1/namespaces/lab/finalize -f -", check=True)

print("✅ Cleanup completed!")
