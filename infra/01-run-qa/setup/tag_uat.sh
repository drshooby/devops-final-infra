#!/bin/bash
set -euo pipefail

echo "🏷️ Tagging QA images as UAT..."
REGION="us-east-1"
INPUT_FILE="$(pwd)/qa_images.txt"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
  echo "❌ Error: $INPUT_FILE not found. Please run pull_images.sh first."
  exit 1
fi

# Read the input file line by line
while IFS=, read -r repo digest; do
  echo "🔍 Processing $repo with digest $digest..."
  
  if [ -z "$digest" ] || [ "$digest" == "None" ]; then
    echo "⚠️ No digest information for $repo"
    continue
  fi
  
  # Check if this digest is already tagged with "uat"
  existing_tags=$(aws ecr list-images \
    --repository-name "$repo" \
    --filter "tagStatus=TAGGED" \
    --query "imageIds[?imageDigest=='$digest'].imageTag" \
    --output json \
    --region "$REGION")
  
  # Check if "uat" is already in the tags list
  if echo "$existing_tags" | grep -q "uat"; then
    echo "✅ Image $repo with digest $digest is already tagged as 'uat' - skipping"
    continue
  fi
  
  echo "🏷️ Image needs UAT tag - proceeding..."
  
  # Get the image manifest for that digest
  manifest=$(aws ecr batch-get-image \
    --repository-name "$repo" \
    --image-ids imageDigest="$digest" \
    --region "$REGION" \
    --query "images[0].imageManifest" \
    --output text)
  
  if [ -z "$manifest" ] || [ "$manifest" == "None" ]; then
    echo "❌ Failed to get manifest for $repo with digest $digest"
    continue
  fi
  
  # Tag the image with "uat"
  echo "🏷️ Tagging $repo digest $digest as 'uat'..."
  aws ecr put-image \
    --repository-name "$repo" \
    --image-tag "uat" \
    --image-manifest "$manifest" \
    --region "$REGION"
  
  echo "✅ Tagged $repo image as 'uat'"
done < "$INPUT_FILE"

echo "🎯 All applicable images now tagged with 'uat'."