#!/bin/bash
set -euo pipefail

echo "  Destroying all Helm releases..."
helm uninstall ingress-nginx -n ingress-nginx || true
helm uninstall external-secrets -n external-secrets || true
helm uninstall cert-manager -n cert-manager || true
helm uninstall argo-rollouts -n argo-rollouts || true

echo " Deleting namespaces..."
kubectl delete ns ingress-nginx external-secrets cert-manager argo-rollouts --ignore-not-found

echo " Deleting all deployments, services, ingresses, rollouts, and secrets..."
kubectl delete deploy,svc,ingress,rollout,secret --all || true

echo " Deleting all ExternalSecrets and SecretStores..."
kubectl delete externalsecret --all || true
kubectl delete secretstore,clustersecretstore --all || true

echo " Killing config maps and CRDs (optional)..."
kubectl delete configmap --all || true

kubectl delete crd certificaterequests.cert-manager.io \
  certificates.cert-manager.io \
  challenges.acme.cert-manager.io \
  clusterissuers.cert-manager.io \
  issuers.cert-manager.io \
  orders.acme.cert-manager.io \
  rollouts.argoproj.io || true

kubectl delete job db-seeder || true

echo " Cluster cleaned up. Time for a fresh start."