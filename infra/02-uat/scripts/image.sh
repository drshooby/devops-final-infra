#!/bin/bash
set -euo pipefail

# Usage: ./image.sh SERVICE_NAME VERSION_TAG

if [[ $# -ne 2 ]]; then
  echo "❌ Usage: $0 SERVICE_NAME VERSION_TAG"
  exit 1
fi

SERVICE=$1
TAG=$2

echo "🔍 Getting AWS Account ID..."
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

echo "🚀 Deploying $SERVICE with tag $TAG from account $AWS_ACCOUNT_ID"

# Export only the vars we want to substitute
export SERVICE
export IMAGE_TAG=$TAG
export AWS_ACCOUNT_ID

# Define paths
SERVICE_DIR="../k8s/$SERVICE"
DEPLOY_YAML="$SERVICE_DIR/$SERVICE.yaml"
SECRET_YAML="$SERVICE_DIR/external-secrets.yaml"

# Deploy secret if it exists
if [[ -f "$SECRET_YAML" ]]; then
  echo "🔐 Applying ExternalSecret for $SERVICE..."
  kubectl apply -f "$SECRET_YAML"
else
  echo "ℹ️ No external-secrets.yaml found for $SERVICE. Skipping secret setup."
fi

# Deploy the service
if [[ -f "$DEPLOY_YAML" ]]; then
  echo "📦 Applying Deployment for $SERVICE..."
  envsubst '${AWS_ACCOUNT_ID} ${SERVICE} ${IMAGE_TAG}' < "$DEPLOY_YAML" | kubectl apply -f -
else
  echo "❌ Deployment YAML not found: $DEPLOY_YAML"
  exit 1
fi
