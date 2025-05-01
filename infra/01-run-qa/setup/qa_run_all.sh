#!/bin/bash

set -euo pipefail

echo "🚀 Starting QA..."

# Make sure scripts are executable
chmod +x ./qa/*.sh

# Step 1: Download setup files from S3
echo "📁 Copying files from S3..."
./qa/s3.sh

# Step 2: Pull the latest QA images
echo "🐋 Pulling latest QA images..."
./qa/pull_images.sh

# Step 3: Spin up our Docker QA images
echo "📁 Spinning up QA environment..."
./qa/compose.sh

# Step 4: Wait for services to settle
echo "⏳ Waiting for containers to initialize..."
sleep 10

# Step 5: Run smoke tests
echo "🧪 Running smoke tests..."
./qa/smoke_test.sh

echo "✅ QA complete."