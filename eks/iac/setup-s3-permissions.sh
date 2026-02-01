#!/bin/bash

# Get EKS cluster OIDC issuer
CLUSTER_NAME="sas-6881323-eks"
OIDC_ISSUER=$(aws eks describe-cluster --name $CLUSTER_NAME --region sa-east-1 --query "cluster.identity.oidc.issuer" --output text)
OIDC_ID=$(echo $OIDC_ISSUER | cut -d '/' -f 5)

# Create trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::248189947068:oidc-provider/oidc.eks.sa-east-1.amazonaws.com/id/$OIDC_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.sa-east-1.amazonaws.com/id/$OIDC_ID:sub": "system:serviceaccount:default:kafka-connect-sa"
        }
      }
    }
  ]
}
EOF

# Update IAM role trust policy
aws iam update-assume-role-policy \
  --role-name KafkaConnectS3Role \
  --policy-document file://trust-policy.json

# Create service account with annotation
kubectl create serviceaccount kafka-connect-sa || echo "ServiceAccount already exists"
kubectl annotate serviceaccount kafka-connect-sa eks.amazonaws.com/role-arn=arn:aws:iam::248189947068:role/KafkaConnectS3Role --overwrite

echo "Setup complete. Update your Kafka Connect deployment to use serviceAccountName: kafka-connect-sa"
