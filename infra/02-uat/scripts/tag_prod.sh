#!/bin/bash
set -euo pipefail

echo " Tagging UAT images as PROD..."
REGION="us-east-1"
INPUT_FILE="$(pwd)/deployed_images.txt"

if [ ! -f "$INPUT_FILE" ]; then
  echo " Error: $INPUT_FILE not found. Please generate it from UAT first."
  exit 1
fi

while IFS=, read -r repo digest; do
  echo " Processing $repo with digest $digest..."

  if [ -z "$digest" ] || [ "$digest" == "None" ]; then
    echo " No digest information for $repo"
    continue
  fi

  existing_tags=$(aws ecr list-images \
    --repository-name "$repo" \
    --filter "tagStatus=TAGGED" \
    --query "imageIds[?imageDigest=='$digest'].imageTag" \
    --output json \
    --region "$REGION")

  if echo "$existing_tags" | grep -q "prod"; then
    echo " Image $repo with digest $digest is already tagged as 'prod' - skipping"
    continue
  fi

  manifest=$(aws ecr batch-get-image \
    --repository-name "$repo" \
    --image-ids imageDigest="$digest" \
    --region "$REGION" \
    --query "images[0].imageManifest" \
    --output text)

  if [ -z "$manifest" ] || [ "$manifest" == "None" ]; then
    echo " Failed to get manifest for $repo with digest $digest"
    continue
  fi

  echo " Tagging $repo digest $digest as 'prod'..."
  aws ecr put-image \
    --repository-name "$repo" \
    --image-tag "prod" \
    --image-manifest "$manifest" \
    --region "$REGION"

  echo " Tagged $repo image as 'prod'"
done < "$INPUT_FILE"

echo " All applicable images now tagged with 'prod'."

echo "Deleting image file"
rm deployed_images.txt