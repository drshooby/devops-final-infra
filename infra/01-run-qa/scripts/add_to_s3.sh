#!/bin/bash

set -euo pipefail

BUCKET_NAME="qa-bucket-ds-final-2025"
SOURCE_DIR="setup"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "❌ Directory '$SOURCE_DIR' does not exist."
  exit 1
fi

echo "🚀 Uploading all files from '$SOURCE_DIR/' to s3://$BUCKET_NAME/scripts/"

aws s3 cp "$SOURCE_DIR" "s3://$BUCKET_NAME/qa-setup/" --recursive

echo "✅ Upload complete."