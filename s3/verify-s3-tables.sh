#!/bin/bash
set -e

REGION="${AWS_REGION:-us-east-1}"
TABLE_BUCKET_NAME="kafka-ifood-tbl"

echo "🔍 Checking S3 Tables deployment..."

# Check if table bucket exists
BUCKET_EXISTS=$(aws s3tables list-table-buckets --region $REGION --query "tableBuckets[?name=='$TABLE_BUCKET_NAME'].arn" --output text)

if [ -z "$BUCKET_EXISTS" ]; then
    echo "❌ Table bucket $TABLE_BUCKET_NAME does not exist"
    echo "Creating table bucket..."
    aws s3tables create-table-bucket --name $TABLE_BUCKET_NAME --region $REGION
    echo "✅ Table bucket created"
else
    echo "✅ Table bucket already exists: $BUCKET_EXISTS"
fi

echo ""
echo "📦 Table Bucket Details:"
aws s3tables list-table-buckets --region $REGION --query "tableBuckets[?name=='$TABLE_BUCKET_NAME']" --output table

echo ""
echo "✅ S3 Tables setup complete!"
