#!/bin/bash
set -e

echo "🌐 Setting up Route53 DNS for lab.dataiesb.com..."

# Get ALB hostname
ALB_HOSTNAME=$(kubectl get ingress lab-ingress -n lab -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [ -z "$ALB_HOSTNAME" ]; then
    echo "❌ Error: Could not get ALB hostname. Make sure ingress is deployed."
    exit 1
fi

echo "📍 ALB Hostname: $ALB_HOSTNAME"

# Wait for ALB to be active
echo "⏳ Waiting for ALB to be active..."
for i in {1..30}; do
    ALB_STATE=$(aws elbv2 describe-load-balancers --region sa-east-1 \
        --query "LoadBalancers[?DNSName=='$ALB_HOSTNAME'].State.Code" --output text)
    if [ "$ALB_STATE" = "active" ]; then
        echo "✅ ALB is active"
        break
    fi
    echo "Waiting... ($i/30) - Current state: $ALB_STATE"
    sleep 10
done

if [ "$ALB_STATE" != "active" ]; then
    echo "⚠️ Warning: ALB is not active yet, but continuing..."
fi

# Get hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --query "HostedZones[?Name=='dataiesb.com.'].Id" --output text | cut -d'/' -f3)

if [ -z "$HOSTED_ZONE_ID" ]; then
    echo "❌ Error: Could not find hosted zone for dataiesb.com"
    exit 1
fi

echo "🔍 Hosted Zone ID: $HOSTED_ZONE_ID"

# Get ALB hosted zone ID dynamically
ALB_ZONE_ID=$(aws elbv2 describe-load-balancers \
    --query "LoadBalancers[?DNSName=='$ALB_HOSTNAME'].CanonicalHostedZoneId" \
    --output text --region sa-east-1)

echo "🔍 ALB Zone ID: $ALB_ZONE_ID"

# Create Route53 change batch
cat > /tmp/route53-change.json <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "lab.dataiesb.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$ALB_ZONE_ID",
          "DNSName": "$ALB_HOSTNAME",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

echo "📝 Creating DNS record..."
aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch file:///tmp/route53-change.json

rm /tmp/route53-change.json

echo "✅ DNS record created successfully!"
echo "🌐 lab.dataiesb.com -> $ALB_HOSTNAME"
echo "⏳ DNS propagation may take a few minutes"
