#!/bin/bash

# Get cluster OIDC issuer
CLUSTER_NAME="lab-cluster"
OIDC_ISSUER=$(aws eks describe-cluster --name $CLUSTER_NAME --query "cluster.identity.oidc.issuer" --output text)
OIDC_ID=$(echo $OIDC_ISSUER | cut -d '/' -f 5)

echo "OIDC ID: $OIDC_ID"

# Update trust policy with actual OIDC ID
sed "s/YOUR_CLUSTER_OIDC_ID/$OIDC_ID/g" trust-policy.json > trust-policy-updated.json

# Create IAM role
aws iam create-role \
  --role-name kafka-connect-s3-role \
  --assume-role-policy-document file://trust-policy-updated.json

# Attach S3 policy
aws iam attach-role-policy \
  --role-name kafka-connect-s3-role \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess

echo "IAM role created: arn:aws:iam::248189947068:role/kafka-connect-s3-role"
