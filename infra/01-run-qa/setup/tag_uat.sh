#!/bin/bash
set -euo pipefail

echo "🏷️ Tagging QA images as UAT..."

REPOS=("frontend" "list-service" "metric-service" "email-service")
REGION="us-east-1"

for repo in "${REPOS[@]}"; do
  echo "🔍 Checking $repo..."

  # Get the digest of the image tagged "qa"
  digest=$(aws ecr list-images \
    --repository-name "$repo" \
    --filter tagStatus=TAGGED \
    --region "$REGION" \
    --query "imageIds[?imageTag=='qa'].imageDigest" \
    --output text)

  if [ -z "$digest" ]; then
    echo "⚠️ No QA image found for $repo"
    continue
  fi

  echo "🔍 Found QA digest: $digest"

  # Get the image manifest for that digest
  manifest=$(aws ecr batch-get-image \
    --repository-name "$repo" \
    --image-ids imageDigest="$digest" \
    --region "$REGION" \
    --query "images[0].imageManifest" \
    --output text)

  # Tag the image with "uat"
  aws ecr put-image \
    --repository-name "$repo" \
    --image-tag "uat" \
    --image-manifest "$manifest" \
    --region "$REGION"

  echo "✅ Tagged $repo image as 'uat'"
done

echo "🎯 All applicable images now tagged with 'uat'."