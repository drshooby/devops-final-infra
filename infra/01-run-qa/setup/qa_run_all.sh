#!/bin/bash

set -euo pipefail

echo " Starting QA..."

# Move into the QA directory
cd ./qa

# Make sure scripts are executable
chmod +x *.sh

echo " Verifying contents of $(pwd)..."
ls -la

# Step 0: Confirm Docker availability
echo " Docker version:"
docker --version || echo " Docker not installed"

echo " Docker daemon status:"
systemctl is-active docker || echo " Docker not running"

# Step 1a: Pull the latest QA images
echo " Pulling latest QA images..."
./pull_images.sh

# Step 1b:
echo "Docker ps -a before compose!"
docker ps -a

# Step 1c:
echo "Checking pulled images"
docker images

# Step 2: Spin up our Docker QA images
echo " Spinning up QA environment..."
./compose.sh

# Step 3: Wait for services to settle
echo " Waiting for containers to initialize..."
sleep 10

# Step 3b:
echo "Docker ps -a after compose!"
docker ps -a

# Step 4: Run smoke tests
echo " Running smoke tests..."
./smoke_test.sh

echo " QA complete."

# Step 5: Tag images for UAT
echo " Tagging images for UAT..."
./tag_uat.sh

echo " Successfully retagged images for UAT."