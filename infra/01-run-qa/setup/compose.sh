#!/bin/bash

set -euo pipefail

COMPOSE_FILE="qa-compose.yml"

echo "🚀 Spinning up containers with Docker Compose..."
docker compose -f "./qa/$COMPOSE_FILE" up -d

echo "✅ QA environment is up and running."