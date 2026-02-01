#!/bin/bash
set -e

# ECR repository details
ECR_REGISTRY="248189947068.dkr.ecr.us-east-1.amazonaws.com"
ECR_REPO="kafka-connect-debezium"
IMAGE_TAG="latest"

echo "🏗️ Building and pushing Kafka Connect image with Debezium connectors..."

# Check if user wants to rebuild
if docker images | grep -q "$ECR_REPO:$IMAGE_TAG"; then
    read -p "Image exists locally. Rebuild? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping build, using existing image"
        exit 0
    fi
fi

# Create ECR repository if it doesn't exist
echo "📦 Checking ECR repository..."
if ! aws ecr describe-repositories --repository-names $ECR_REPO --region us-east-1 >/dev/null 2>&1; then
    echo "Creating ECR repository..."
    aws ecr create-repository --repository-name $ECR_REPO --region us-east-1
else
    echo "ECR repository already exists"
fi

# Login to ECR
echo "🔐 Logging into ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_REGISTRY

# Build image
echo "🔨 Building Docker image..."
docker build -f Dockerfile -t $ECR_REPO:$IMAGE_TAG .

# Tag for ECR
echo "🏷️ Tagging image for ECR..."
docker tag $ECR_REPO:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG

# Push to ECR
echo "📤 Pushing image to ECR..."
docker push $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG

echo "✅ Image successfully pushed to: $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG"
