#!/bin/bash

set -e

echo "🔍 Checking service health endpoints..."

curl -fs http://localhost:8000/api/email/health && echo "✅ email-service is up" || echo "❌ email-service failed"
curl -fs http://localhost:8001/api/list/health && echo "✅ list-service is up" || echo "❌ list-service failed"
curl -fs http://localhost:8002/api/metric/health && echo "✅ metric-service is up" || echo "❌ metric-service failed"
curl -fs http://localhost:8080 && echo "✅ web is up" || echo "❌ web failed"

echo "✅ Health check complete."