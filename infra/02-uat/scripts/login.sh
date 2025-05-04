#!/bin/bash

set -euo pipefail

REGISTRY="id.dkr.ecr.us-east-1.amazonaws.com"
SECRET_NAME="regcred"
NAMESPACE="default" # change this if you're not using 'default'

# Make sure you're logged in with AWS CLI
echo "🔐 Getting ECR password..."
PASSWORD=$(aws ecr get-login-password --region us-east-1)

if [ -z "$PASSWORD" ]; then
  echo "❌ Failed to get password. Is your AWS session configured?"
  exit 1
fi

# Delete the old secret if it exists
kubectl delete secret "$SECRET_NAME" --namespace "$NAMESPACE" --ignore-not-found

# Create the secret manually
kubectl create secret docker-registry "$SECRET_NAME" \
  --docker-server="$REGISTRY" \
  --docker-username=AWS \
  --docker-password="$PASSWORD" \
  --docker-email=dev@shoob.studio \
  --namespace "$NAMESPACE"
