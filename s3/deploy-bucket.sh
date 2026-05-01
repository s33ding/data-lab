#!/bin/bash
set -e

REGION="${AWS_REGION:-us-east-1}"
TABLE_BUCKET_NAME="kafka-ifood-tbl"

echo "🔍 Verifying S3 Tables setup..."

# Check if table bucket exists
BUCKET_ARN=$(aws s3tables list-table-buckets --region $REGION --query "tableBuckets[?name=='$TABLE_BUCKET_NAME'].arn" --output text)

if [ -z "$BUCKET_ARN" ]; then
    echo "❌ Table bucket does not exist. Creating..."
    aws s3tables create-table-bucket --name $TABLE_BUCKET_NAME --region $REGION
    echo "✅ Table bucket created"
else
    echo "✅ Table bucket exists: $BUCKET_ARN"
fi

echo ""
echo "📦 S3 Tables Details:"
aws s3tables list-table-buckets --region $REGION --output table

echo ""
echo "✅ S3 Tables verified successfully!"
echo ""
echo "Note: This is an S3 Tables bucket, not a regular S3 bucket."
echo "Use Athena with S3 Tables catalog to query data."

