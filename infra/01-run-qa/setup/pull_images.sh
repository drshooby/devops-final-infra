#!/bin/bash
set -euo pipefail

REPOS=("frontend" "list-service" "metric-service" "email-service")
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION="us-east-1"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

echo "🔑 Logging into ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"

for repo in "${REPOS[@]}"; do
  echo "🔍 Resolving QA tag digest for $repo..."

  qa_digest=$(aws ecr list-images \
    --repository-name "$repo" \
    --filter tagStatus=TAGGED \
    --region "$REGION" \
    --query "imageIds[?imageTag=='qa'].imageDigest" \
    --output text)

  if [ -z "$qa_digest" ]; then
    echo "⚠️ QA tag not found for $repo"
    continue
  fi

  echo "🔍 Finding matching version tag with digest $qa_digest..."

  version_tag=$(aws ecr list-images \
    --repository-name "$repo" \
    --filter tagStatus=TAGGED \
    --region "$REGION" \
    --query 'imageIds[].[imageTag, imageDigest]' \
    --output text | \
    awk -v digest="$qa_digest" '$2 == digest && $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+-[0-9]{8}$/ { print $1 }' | \
    sort -Vr | \
    head -n 1)

  if [ -n "$version_tag" ]; then
    echo "🚀 Pulling $repo:$version_tag"
    docker pull "$ECR_URL/$repo:$version_tag"

    echo "🏷️ Tagging as $repo for Compose"
    docker tag "$ECR_URL/$repo:$version_tag" "$repo"
  else
    echo "⚠️ No matching version tag found for QA digest on $repo"
  fi
done

echo "✅ QA image pull and tagging complete."