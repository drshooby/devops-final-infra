#!/bin/bash
set -euo pipefail

AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)

export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

if [[ -z "$AWS_ACCESS_KEY_ID" || -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "❌ AWS credentials not found in config. Please run 'aws configure' first."
  exit 1
fi

CLUSTER_NAME="prod-cluster"
REGION="us-east-1"

echo "Permissions granted"
chmod +x ./*.sh

echo "⚙️  Updating kubeconfig for cluster: $CLUSTER_NAME..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"

echo "🛠️  Creating namespace for External Secrets if it doesn't exist..."
kubectl create namespace external-secrets --dry-run=client -o yaml | kubectl apply -f -

echo "Creating aws-creds secret"
kubectl create secret generic aws-creds \
  --from-literal=access-key="$AWS_ACCESS_KEY_ID" \
  --from-literal=secret-access-key="$AWS_SECRET_ACCESS_KEY" \
  --namespace=external-secrets --dry-run=client -o yaml | kubectl apply -f - --validate=false

echo "📦 Installing NGINX ingress controller via Helm..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

echo "📦 Installing External Secrets via Helm..."
helm repo add external-secrets https://charts.external-secrets.io || true
helm repo update
helm install external-secrets external-secrets/external-secrets \
    --namespace external-secrets \
    --create-namespace

echo "📦 Installing cert-manager with CRDs..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true

# kubectl port-forward deployment/argo-rollouts-dashboard -n argo-rollouts 3100:3100
echo "📦 Installing Argo Rollouts controller..."
helm repo add argo https://argoproj.github.io/argo-helm || true
helm repo update
helm upgrade --install argo-rollouts argo/argo-rollouts \
  --namespace argo-rollouts \
  --create-namespace \
  --set dashboard.enabled=true

echo "🔐 Creating ECR pull secret (regcred)..."
./create_regcred.sh

echo "⏳ Waiting for external-secrets webhook to be ready..."
kubectl wait --namespace external-secrets \
  --for=condition=available deployment/external-secrets-webhook \
  --timeout=120s

echo "🔑 Setting up AWS SecretStore (External Secrets)..."
kubectl apply -f ../k8s/shared/aws-cluster-secret-store.yaml

echo "Setting up ClusterIssuer (SSL)..."
kubectl apply -f ../k8s/ssl/cluster-issuer.yaml

echo "🔧 Deploying seeder..."
kubectl create configmap seed-sql --from-file=../k8s/seeder/init.sql --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f "../k8s/seeder/external-secrets.yaml"
kubectl apply -f "../k8s/seeder/seeder-job.yaml"

echo "🧬 Deploying microservices..."
./image.sh email-service 1.2.0-20250505
./image.sh list-service 1.2.0-20250505
./image.sh metric-service 1.2.1-20250505
./image.sh frontend 1.2.0-20250505

echo "🌐 Applying ingress for frontend..."
kubectl apply -f ../k8s/frontend/frontend-ingress.yaml

echo "Wait a couple seconds before checking pod status"
sleep 5

echo "🩺 Checking service status..."
kubectl get pods
kubectl get ingress

echo "Updating DNS"
./route53.sh

echo "✅ Run all complete for cluster: $CLUSTER_NAME"