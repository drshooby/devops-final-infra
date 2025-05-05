#!/bin/bash
set -euo pipefail

echo "☠️  Destroying all Helm releases..."
helm uninstall ingress-nginx -n ingress-nginx || true
helm uninstall external-secrets -n external-secrets || true

echo "🧽 Deleting namespaces..."
kubectl delete ns ingress-nginx external-secrets --ignore-not-found

echo "💀 Deleting all deployments, services, ingresses, and secrets..."
kubectl delete deploy,svc,ingress,secret --all || true

echo "🧹 Deleting all ExternalSecrets and SecretStores..."
kubectl delete externalsecret --all || true
kubectl delete secretstore,clustersecretstore --all || true

echo "🧨 Killing config maps and CRDs (optional)..."
kubectl delete configmap --all || true
kubectl delete crd clustersecretstores.external-secrets.io externalsecrets.external-secrets.io \
  secretstores.external-secrets.io || true

kubectl delete job db-seeder

echo "✅ Cluster cleaned up. Time for a fresh start."
