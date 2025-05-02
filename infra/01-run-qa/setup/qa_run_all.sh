#!/bin/bash

set -euo pipefail

echo "🚀 Starting QA..."

# Call S3 pull as part of initial command invocation

# Make sure scripts are executable
chmod +x ./qa/*.sh

# Step 0: Confirm Docker availability
echo "🐳 Docker version:"
docker --version || echo "❌ Docker not installed"

echo "🔧 Docker daemon status:"
systemctl is-active docker || echo "❌ Docker not running"

# Step 1: Pull the latest QA images
echo "🐋 Pulling latest QA images..."
./qa/pull_images.sh

# Step 2: Spin up our Docker QA images
echo "📁 Spinning up QA environment..."
./qa/compose.sh

# Step 3: Wait for services to settle
echo "⏳ Waiting for containers to initialize..."
sleep 10

# Step 4: Run smoke tests
echo "🧪 Running smoke tests..."
./qa/smoke_test.sh

echo "✅ QA complete."