#!/bin/bash
set -euo pipefail

REPOS=("frontend" "list-service" "metric-service" "email-service")
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
REGION="us-east-1"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
OUTPUT_FILE="$(pwd)/qa_images.txt"

# Clear the output file
> "$OUTPUT_FILE"

echo " Logging into ECR..."
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ECR_URL"

for repo in "${REPOS[@]}"; do
  echo " Finding latest QA tagged image for $repo..."

  # Get all images with the qa tag and sort by pushed date to find the latest one
  latest_qa_image=$(aws ecr describe-images \
    --repository-name "$repo" \
    --filter "tagStatus=TAGGED" \
    --query "sort_by(imageDetails[?contains(imageTags, 'qa')], &imagePushedAt)[-1:].{digest:imageDigest,tags:imageTags,pushed:imagePushedAt}" \
    --output json \
    --region "$REGION" 2>/dev/null || echo "[]")
  
  # Check if we got any results
  if [ "$latest_qa_image" == "[]" ] || [ -z "$latest_qa_image" ]; then
    echo " No QA tagged images found for $repo"
    continue
  fi
  
  # Extract the digest of the latest qa-tagged image
  qa_digest=$(echo "$latest_qa_image" | jq -r '.[0].digest // empty')
  pushed_date=$(echo "$latest_qa_image" | jq -r '.[0].pushed // "unknown"')
  all_tags=$(echo "$latest_qa_image" | jq -r '.[0].tags | join(", ") // "unknown"')
  
  if [ -z "$qa_digest" ] || [ "$qa_digest" == "null" ]; then
    echo " Could not extract digest for latest QA image of $repo"
    continue
  fi

  echo " Found latest QA image for $repo:"
  echo "   Digest: $qa_digest"
  echo "   Pushed: $pushed_date" 
  echo "   Tags: $all_tags"

  echo " Pulling $repo:qa (digest: $qa_digest)"
  docker pull "$ECR_URL/$repo:qa"

  echo " Tagging as $repo for Compose"
  docker tag "$ECR_URL/$repo:qa" "$repo"

  # Write the repo and digest to the output file
  echo "$repo,$qa_digest" >> "$OUTPUT_FILE"
done

echo " QA image pull and tagging complete. Image information saved to $OUTPUT_FILE"