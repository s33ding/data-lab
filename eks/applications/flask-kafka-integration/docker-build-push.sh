#!/bin/bash

# Build and push to ECR
REGION="sa-east-1"
ACCOUNT_ID="248189947068"
REPO_NAME="flask"
IMAGE_TAG="latest"

# Check if user wants to rebuild
if docker images | grep -q "$REPO_NAME:$IMAGE_TAG"; then
    read -p "Image exists locally. Rebuild? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Skipping build, using existing image"
        exit 0
    fi
fi

# Create ECR repository if it doesn't exist
aws ecr describe-repositories --repository-names $REPO_NAME --region $REGION || \
aws ecr create-repository --repository-name $REPO_NAME --region $REGION

# Get login token
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push
docker build -t $REPO_NAME:$IMAGE_TAG .
docker tag $REPO_NAME:$IMAGE_TAG $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG

echo "Image pushed to: $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"
