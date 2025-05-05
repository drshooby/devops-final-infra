# 🛠️ Kubernetes Setup for Shoob Studio App

This repo contains Kubernetes manifests for deploying the Shoob Studio app into a Kubernetes cluster (UAT or production). It supports a microservice-based architecture using AWS ECR, Secrets Manager, and the External Secrets Operator.

---

## ✅ Prerequisites

- Docker Desktop with Kubernetes enabled (or any K8s cluster)
- AWS CLI configured (`aws configure`)
- ECR repositories already exist (or set up via Terraform)
- Secrets stored in AWS Secrets Manager
- Helm installed (`brew install helm`)
- Domain (e.g. `uat.shoob.studio`) with DNS pointing to your LoadBalancer IP (use `localhost` for Docker Desktop)

---

## 🔐 1. Set Secrets in AWS Secrets Manager

- Before deploying, make sure these secrets exist:

### Email Service:

- Secret name: `email-service`

```json
{
  "SMTP_HOST": "...",
  "SMTP_USERNAME": "...",
  "SMTP_PASSWORD": "...",
  "FROM_EMAIL": "..."
}
```

### List and Metric Services:

- Secret name: `shared-pg`
- Make sure to add `postgresql+asyncpg` at the beginning and `?sslmode=require` at the end

```json
{
  "POSTGRES_URL": "..."
}
```

## 📦 2. Install External Secrets Operator

```bash
  helm repo add external-secrets https://charts.external-secrets.io
  helm repo update

  helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace
```

then apply it:
```bash
  kubectl apply -f ./k8s/shared/aws-cluster-secret-store.yaml
```

## 🔐 3. Create ECR Pull Secret
```bash
./scripts/create_regcred.sh
```

## 🚀 4. Deploy Services

- Each service lives in `k8s/<service>/`. To deploy:

`./scripts/image.sh <service-name> <image-tag>`

Example:

`./scripts/image.sh frontend 1.1.5-20250704`

## 🌐 5. Configure Ingress (Frontend Only)

- Your `frontend/frontend-ingress.yaml` exposes the app at: `http://uat.shoob.studio`

Make sure:

- You have an Ingress controller installed (NGINX)
- DNS (A record) for uat.shoob.studio points to your LoadBalancer IP
- Verify with `kubectl get svc -n ingress-nginx`
- Look for the `EXTERNAL-IP` and match it in your domain registrar.

## 🧼 6. Restart or Kill Pods

### To restart all microservices:

```bash
kubectl rollout restart deploy/frontend
kubectl rollout restart deploy/email-service
kubectl rollout restart deploy/list-service
kubectl rollout restart deploy/metric-service
```

## 🧪 7. Troubleshooting Tips

- Check for image pull issues: `kubectl describe pod <pod-name>`
- Check logs: `kubectl logs deploy/<service>`
- Verify secrets exist: `kubectl get secret`
- Debug ingress: `kubectl get ingress, kubectl describe ingress`