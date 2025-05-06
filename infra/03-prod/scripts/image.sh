#!/bin/bash
set -euo pipefail

# Usage: ./image.sh SERVICE_NAME VERSION_TAG

if [[ $# -ne 2 ]]; then
  echo "❌ Usage: $0 SERVICE_NAME VERSION_TAG"
  exit 1
fi

SERVICE=$1
TAG=$2

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
export SERVICE
export IMAGE_TAG=$TAG
export AWS_ACCOUNT_ID

SERVICE_DIR="../k8s/$SERVICE"
ROLLOUT_YAML="$SERVICE_DIR/$SERVICE-rollout.yaml"
SERVICE_YAML="$SERVICE_DIR/$SERVICE.yaml"
PREVIEW_YAML="$SERVICE_DIR/${SERVICE}-preview.yaml"
SECRET_YAML="$SERVICE_DIR/external-secrets.yaml"

# Apply secrets if needed
if [[ -f "$SECRET_YAML" ]]; then
  echo "🔐 Applying ExternalSecret for $SERVICE..."
  kubectl apply -f "$SECRET_YAML"
else
  echo "ℹ️ No external-secrets.yaml for $SERVICE. Skipping secrets..."
fi

# Special case: frontend does NOT use Argo Rollouts
if [[ "$SERVICE" == "frontend" ]]; then
  echo "📦 Applying regular Deployment for $SERVICE..."
  envsubst '${AWS_ACCOUNT_ID} ${SERVICE} ${IMAGE_TAG}' < "$SERVICE_YAML" | kubectl apply -f -
  echo "✅ $SERVICE deployed with tag: $TAG (non-rollout)"
  exit 0
fi

# Check current image if Rollout exists
CURRENT_IMAGE=$(kubectl get rollout "$SERVICE" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "")
NEW_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/${SERVICE}:${IMAGE_TAG}"

if [[ "$CURRENT_IMAGE" == "$NEW_IMAGE" ]]; then
  echo "⏩ $SERVICE is already running image $IMAGE_TAG — skipping rollout"
  exit 0
fi

# Apply rollout and services
if [[ -f "$ROLLOUT_YAML" ]]; then
  echo "🌀 Applying Argo Rollout for $SERVICE..."
  envsubst '${AWS_ACCOUNT_ID} ${SERVICE} ${IMAGE_TAG}' < "$ROLLOUT_YAML" | kubectl apply -f -
else
  echo "❌ Rollout YAML not found for $SERVICE!"
  exit 1
fi

echo "🔧 Applying active and preview services for $SERVICE..."
kubectl apply -f "$SERVICE_YAML"
kubectl apply -f "$PREVIEW_YAML"

echo "✅ $SERVICE rollout applied with tag: $TAG"