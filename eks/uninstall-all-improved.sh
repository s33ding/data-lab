#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to safely delete resources
safe_delete() {
    local resource_type=$1
    local resource_name=$2
    local namespace=${3:-"default"}
    
    if kubectl get $resource_type $resource_name -n $namespace &>/dev/null; then
        print_status "Deleting $resource_type/$resource_name in namespace $namespace"
        kubectl delete $resource_type $resource_name -n $namespace --timeout=60s || print_warning "Failed to delete $resource_type/$resource_name"
    else
        print_warning "$resource_type/$resource_name not found in namespace $namespace"
    fi
}

# Function to delete connectors
delete_connectors() {
    print_status "Deleting Kafka connectors..."
    
    local connect_pod=$(kubectl get pods -l app=kafka-connect -o jsonpath='{.items[0].metadata.name}' -n lab 2>/dev/null || echo "")
    
    if [[ -n "$connect_pod" ]]; then
        # List and delete all connectors
        local connectors=$(kubectl exec -n lab $connect_pod -- curl -s http://localhost:8083/connectors 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
        
        if [[ -n "$connectors" ]]; then
            for connector in $connectors; do
                print_status "Deleting connector: $connector"
                kubectl exec -n lab $connect_pod -- curl -X DELETE http://localhost:8083/connectors/$connector || print_warning "Failed to delete connector $connector"
            done
        else
            print_warning "No connectors found"
        fi
    else
        print_warning "Kafka Connect pod not found"
    fi
}

# Function to check if namespace exists
namespace_exists() {
    kubectl get namespace $1 &>/dev/null
}

echo -e "${BLUE}🗑️ Starting comprehensive Kafka EKS cleanup...${NC}"

# Check if lab namespace exists
if ! namespace_exists "lab"; then
    print_warning "Lab namespace doesn't exist, checking default namespace"
    NAMESPACE="default"
else
    NAMESPACE="lab"
fi

# 1. Delete connectors first (graceful shutdown)
delete_connectors

# 2. Delete applications
print_status "Deleting applications..."
safe_delete "deployment" "flask-kafka-integration" $NAMESPACE
safe_delete "service" "flask-kafka-integration" $NAMESPACE
safe_delete "deployment" "kafka-playground" $NAMESPACE
safe_delete "service" "kafka-playground-service" $NAMESPACE

# 3. Delete monitoring
print_status "Deleting monitoring components..."
safe_delete "deployment" "kafka-ui" $NAMESPACE
safe_delete "service" "kafka-ui" $NAMESPACE
safe_delete "deployment" "grafana" $NAMESPACE
safe_delete "service" "grafana" $NAMESPACE
safe_delete "deployment" "prometheus" $NAMESPACE
safe_delete "service" "prometheus" $NAMESPACE

# 4. Delete Kafka Connect
print_status "Deleting Kafka Connect..."
safe_delete "kafkaconnect" "kafka-connect-proper" $NAMESPACE
safe_delete "service" "kafka-connect-proper" $NAMESPACE

# 5. Delete PostgreSQL
print_status "Deleting PostgreSQL..."
safe_delete "deployment" "postgres" $NAMESPACE
safe_delete "service" "postgres" $NAMESPACE
safe_delete "pvc" "postgres-pvc" $NAMESPACE

# 6. Delete Kafka infrastructure (order matters)
print_status "Deleting Kafka infrastructure..."
safe_delete "kafka" "kafka-brokers" $NAMESPACE
safe_delete "kraftcontroller" "kraftcontroller" $NAMESPACE
safe_delete "kraftcontroller" "kraft-controller" $NAMESPACE

# 7. Delete all PVCs in namespace
print_status "Deleting all PVCs in namespace $NAMESPACE..."
kubectl get pvc -n $NAMESPACE -o name 2>/dev/null | xargs -r kubectl delete -n $NAMESPACE --timeout=60s || print_warning "No PVCs to delete or deletion failed"

# 8. Wait for Kafka resources to be deleted
print_status "Waiting for Kafka resources to be fully deleted..."
sleep 30

# 9. Delete Confluent Operator
if helm list -n $NAMESPACE | grep -q confluent-operator; then
    print_status "Uninstalling Confluent Operator..."
    helm uninstall confluent-operator -n $NAMESPACE || print_warning "Failed to uninstall Confluent Operator"
else
    print_warning "Confluent Operator not found"
fi

# 10. Delete ingress resources
print_status "Deleting ingress resources..."
safe_delete "ingress" "lab-ingress" $NAMESPACE
safe_delete "ingress" "ingress-iesb" "default"

# 11. Delete persistent volumes
print_status "Cleaning up persistent volumes..."
kubectl get pv | grep $NAMESPACE | awk '{print $1}' | xargs -r kubectl delete pv || print_warning "No PVs to delete"

# 12. Clean up IAM resources (be careful here)
print_status "Cleaning up IAM resources..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "")

if [[ -n "$ACCOUNT_ID" ]]; then
    # Detach and delete policy
    aws iam detach-role-policy --role-name kafka-s3-role --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/kafka-s3-policy 2>/dev/null || print_warning "Policy not attached or doesn't exist"
    aws iam delete-role --role-name kafka-s3-role 2>/dev/null || print_warning "Role kafka-s3-role not found"
    aws iam delete-policy --policy-arn arn:aws:iam::$ACCOUNT_ID:policy/kafka-s3-policy 2>/dev/null || print_warning "Policy kafka-s3-policy not found"
else
    print_warning "Could not get AWS account ID, skipping IAM cleanup"
fi

# 13. Optional: Delete namespace (ask user)
if [[ "$NAMESPACE" == "lab" ]]; then
    read -p "Do you want to delete the 'lab' namespace? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Deleting lab namespace..."
        kubectl delete namespace lab --timeout=120s || print_warning "Failed to delete lab namespace"
    else
        print_warning "Keeping lab namespace"
    fi
fi

# 13. Final cleanup check
print_status "Performing final cleanup check..."
remaining_resources=$(kubectl get all -n $NAMESPACE 2>/dev/null | grep -v "service/kubernetes" | wc -l)
if [[ $remaining_resources -gt 1 ]]; then
    print_warning "Some resources may still be running in namespace $NAMESPACE"
    kubectl get all -n $NAMESPACE
else
    print_success "All resources cleaned up successfully"
fi

print_success "🎉 Kafka EKS cleanup completed!"
print_status "Note: Some resources may take a few minutes to fully terminate"
