#!/bin/bash

set -euo pipefail

INSTANCE_ID="$1"
REGION="us-east-1"

echo "🔄 Waiting for EC2 instance $INSTANCE_ID to become SSM-managed..."

for attempt in {1..20}; do
  STATUS=$(aws ssm describe-instance-information \
    --region "$REGION" \
    --query "InstanceInformationList[?InstanceId=='$INSTANCE_ID'].PingStatus" \
    --output text 2>/dev/null || echo "none")

  if [[ "$STATUS" == "Online" ]]; then
    echo "✅ Instance $INSTANCE_ID is online in SSM and ready."
    exit 0
  fi

  echo "⏳ SSM status: $STATUS. Waiting 7s..."
  sleep 7
done

echo "❌ Instance $INSTANCE_ID did not become SSM-ready in time."
exit 1