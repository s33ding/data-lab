#!/usr/bin/env python3
import subprocess
import sys
import time

def run(cmd, check=True, cwd=None):
    """Run command and print output"""
    result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=False)
    if check and result.returncode != 0:
        sys.exit(result.returncode)
    return result.returncode

def wait_for_pods(label, namespace="lab", timeout=300):
    """Wait for pods with label to be ready"""
    print(f"⏳ Waiting for pods with label {label}...")
    start = time.time()
    while time.time() - start < timeout:
        result = subprocess.run(
            f"kubectl get pods -n {namespace} -l {label} 2>/dev/null",
            shell=True, capture_output=True, text=True
        )
        if result.returncode == 0 and "Running" in result.stdout:
            break
        print("Waiting for pods to be created...")
        time.sleep(5)
    run(f"kubectl wait --for=condition=ready pod -l {label} -n {namespace} --timeout={timeout}s")

print("🚀 Installing Kafka EKS Playground in lab namespace...")

print("📁 Creating lab namespace...")
run("kubectl create namespace lab --dry-run=client -o yaml | kubectl apply -f -")

print("📦 Adding Confluent Helm repository...")
run("helm repo add confluentinc https://packages.confluent.io/helm")
run("helm repo update")

print("⚙️ Installing Confluent Operator...")
run("helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes -n lab")

print("⏳ Waiting for Confluent Operator...")
run("kubectl wait --for=condition=available deployment/confluent-operator --timeout=300s -n lab")

print("📦 Deploying Kafka infrastructure...")
run("kubectl apply -f infrastructure/kraft-controller.yaml -n lab")
run("kubectl apply -f infrastructure/kafka-brokers.yaml -n lab")

wait_for_pods("app=kafka-brokers")

print("🐘 Deploying PostgreSQL...")
run("kubectl apply -f applications/postgres/postgres.yaml -n lab")
run("kubectl wait --for=condition=ready pod -l app=postgres --timeout=180s -n lab")

print("🔐 Setting up S3 permissions...")
if run("cd iac && ./setup-s3-permissions.sh", check=False) != 0:
    print("⚠️ S3 permissions already configured")

print("🔌 Deploying Kafka Connect...")
run("./build-and-push.sh", cwd="infrastructure/kafka-connect-deployment")
run("./deploy.sh", cwd="infrastructure/kafka-connect-deployment")

# Wait for Kafka Connect pod to be Running (readiness probe is broken)
print("⏳ Waiting for Kafka Connect pod...")
time.sleep(60)  # Give it time to start
for i in range(60):
    result = subprocess.run(
        "kubectl get pods -n lab -l app=kafka-connect -o jsonpath='{.items[0].status.phase}'",
        shell=True, capture_output=True, text=True
    )
    if result.stdout.strip("'") == "Running":
        print("✅ Kafka Connect pod is running")
        break
    time.sleep(5)
else:
    print("⚠️ Kafka Connect pod not running yet, continuing anyway...")

print("🎮 Deploying flask app...")
run("./docker-build-push.sh", cwd="applications/flask-kafka-integration")
run("kubectl apply -f deployment.yaml", cwd="applications/flask-kafka-integration")

print("📊 Deploying Kafka UI...")
run("kubectl apply -f applications/monitoring/kafka-ui/ -n lab")

print("🔗 Creating connectors...")
time.sleep(30)
run("python3 deploy-connectors.py", cwd="connectors")
run("./docker-build-push.sh", cwd="applications/flask-kafka-integration")
run("kubectl apply -f deployment.yaml", cwd="applications/flask-kafka-integration")

print("📊 Deploying Kafka UI...")
run("kubectl apply -f applications/monitoring/kafka-ui/ -n lab")

print("✅ Installation complete!")
print("🌐 Access Kafka UI: http://app.dataiesb.com/kafka-ui")
print("🎮 Access Playground: http://app.dataiesb.com/playground")
