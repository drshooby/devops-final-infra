#!/bin/bash

set -euo pipefail

echo " Running smoke tests..."
echo " Checking service health endpoints..."

check_service() {
  local name=$1
  local url=$2
  local expected=$3

  response=$(curl -fs "$url" || true)
  if [[ "$response" == *"$expected"* ]]; then
    echo " $name is up"
  else
    echo " $name failed"
    echo "$response"
    exit 1
  fi
}

check_service "email-service"  "http://localhost:8000/api/email/health"  "Hello"
check_service "list-service"   "http://localhost:8001/api/list/health"   "Hello"
check_service "metric-service" "http://localhost:8002/api/metrics/health" "Hello"
check_service "web"            "http://localhost:8080"                   "<title>Photo App</title>"

echo " Smoke tests complete."