#!/bin/bash

set -euo pipefail

INSTANCE_ID="$1"
REGION="us-east-1"

echo "🚀 Sending SSM command to start QA script on instance $INSTANCE_ID..."

# Send the command and capture Command ID
COMMAND_ID=$(aws ssm send-command \
  --document-name "AWS-RunShellScript" \
  --comment "Start QA" \
  --instance-ids "$INSTANCE_ID" \
  --region "$REGION" \
  --parameters commands=["chmod +x qa_run_all.sh && ./qa_run_all.sh"] \
  --query "Command.CommandId" \
  --output text)

echo "📡 Sent command: $COMMAND_ID"

# Wait for command to complete
echo "⏳ Waiting for command to finish..."
for i in {1..30}; do
  STATUS=$(aws ssm list-command-invocations \
    --region "$REGION" \
    --command-id "$COMMAND_ID" \
    --details \
    --query "CommandInvocations[0].Status" \
    --output text 2>/dev/null || echo "Pending")

  echo "⌛ Status: $STATUS"
  if [[ "$STATUS" == "Success" ]]; then
    echo "✅ QA script completed successfully!"
    break
  elif [[ "$STATUS" == "Failed" || "$STATUS" == "Cancelled" || "$STATUS" == "TimedOut" ]]; then
    echo "❌ QA script failed with status: $STATUS"
    exit 1
  fi

  sleep 10
done

# Output logs
echo "🧾 Fetching command output:"
aws ssm get-command-invocation \
  --region "$REGION" \
  --command-id "$COMMAND_ID" \
  --instance-id "$INSTANCE_ID" \
  --query "StandardOutputContent" \
  --output text
