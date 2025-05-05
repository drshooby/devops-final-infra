#!/bin/bash
set -euo pipefail

HOSTED_ZONE_ID="Z02448152G88LS40W33XK" # replace if needed, this is mine
RECORD_NAME="uat.shoob.studio."
TTL=60

echo "🔍 Waiting for Ingress ELB to be assigned..."

for i in {1..30}; do
  ELB_HOST=$(kubectl get ingress frontend-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
  
  if [[ -n "${ELB_HOST}" && "${ELB_HOST}" != "<no value>" ]]; then
    echo "✅ ELB Host found: $ELB_HOST"
    break
  fi

  echo "⏳ ELB not ready yet... retrying ($i/30)"
  sleep 3
done

if [[ -z "${ELB_HOST:-}" || "${ELB_HOST}" == "<no value>" ]]; then
  echo "❌ Failed to fetch ELB hostname after 30 attempts"
  exit 1
fi

echo "📝 Updating Route53 record..."

cat > /tmp/route53-change-batch.json <<EOF
{
  "Comment": "Update CNAME for frontend ingress",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "CNAME",
        "TTL": $TTL,
        "ResourceRecords": [
          {
            "Value": "$ELB_HOST"
          }
        ]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file:///tmp/route53-change-batch.json

echo "✅ Route 53 CNAME updated: $RECORD_NAME → $ELB_HOST"

echo "⏳ Waiting for DNS to reflect the update..."

for i in {1..30}; do
  RESOLVED=$(dig +short "$RECORD_NAME" | grep "$ELB_HOST" || true)

  if [[ -n "$RESOLVED" ]]; then
    echo "🎉 DNS is synced"
    echo "📜 The SSL certificate may still be propagating. HTTPS should become valid shortly."
    exit 0
  fi

  echo "⌛ Not yet synced... ($i/30)"
  sleep 5
done

echo "❌ DNS did not sync within expected time"
exit 1