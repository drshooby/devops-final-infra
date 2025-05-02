#!/bin/bash

set -euo pipefail

echo "Checking compose file"
docker-compose config

echo "🚀 Spinning up containers with Docker Compose..."
docker-compose up -d

echo "📦 Docker Compose containers:"
docker-compose ps

echo "📄 Showing logs for failed containers (if any):"
docker-compose logs --tail=50

echo "✅ QA environment is up and running."