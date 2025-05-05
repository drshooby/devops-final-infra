#!/bin/bash
set -euo pipefail

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com"
SECRET_NAME="regcred"
NAMESPACE="default"

echo "🔐 Getting ECR password..."
PASSWORD=$(aws ecr get-login-password --region us-east-1)

if [[ -z "$PASSWORD" ]]; then
  echo "❌ Failed to get password from AWS CLI."
  exit 1
fi

echo "🧼 Cleaning up old secret if exists..."
kubectl delete secret "$SECRET_NAME" --namespace "$NAMESPACE" --ignore-not-found

echo "📦 Creating new regcred secret"
kubectl create secret docker-registry "$SECRET_NAME" \
  --docker-server="$REGISTRY" \
  --docker-username=AWS \
  --docker-password="$PASSWORD" \
  --docker-email=none@example.com \
  --namespace "$NAMESPACE"