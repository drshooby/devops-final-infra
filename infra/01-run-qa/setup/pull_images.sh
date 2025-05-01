#!/bin/bash

set -euo pipefail

REPOS=("frontend" "list-service" "metric-service" "email-service")
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION="us-east-1"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "🔑 Logging into ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URL

for repo in "${REPOS[@]}"; do
  echo "🔍 Checking $repo for newest -qa- image..."

  latest_tag=$(aws ecr list-images \
    --repository-name "$repo" \
    --filter tagStatus=TAGGED \
    --region "$REGION" \
    --query 'imageIds[].imageTag' \
    --output text | \
    tr '\t' '\n' | \
    grep '\-qa\-' | \
    sort -r | \
    head -n 1)

  if [ -n "$latest_tag" ]; then
    echo "🚀 Pulling $repo:$latest_tag"
    docker pull "$ECR_URL/$repo:$latest_tag"
  else
    echo "⚠️ No QA image found for $repo"
  fi
done

echo "✅ Image pull complete"