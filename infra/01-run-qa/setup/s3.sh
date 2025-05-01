#!/bin/bash

set -euo pipefail

BUCKET_NAME="qa-bucket-ds-final-2025"
REGION="us-east-1"
FILES_DIR="setup"

echo "📥 Downloading setup files from S3..."
aws s3 cp "s3://$BUCKET_NAME/$FILES_DIR" "./qa" --recursive --region "$REGION"

echo "✅ Files copied from S3."