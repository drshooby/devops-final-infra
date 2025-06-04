# Production-Grade Blue/Green Deployment Pipeline for Microservices

This project is a full-scale DevOps pipeline built as a final project for a university DevOps course. It automates the CI/CD process for multiple microservices across development, QA, UAT, and production environments using modern cloud-native tools.

## Architecture Overview

The pipeline manages three FastAPI-based microservices using separate repositories for application code and infrastructure as code.

[Source Repo](https://github.com/drshooby/devops-final-source)

### Key Features

- Multi-Environment Promotion Pipeline: Supports Dev → QA → UAT → Prod deployment flow.
- Nightly Builds with Semantic Versioning: Services are rebuilt and pushed to AWS ECR only if changes are detected.
- Infrastructure as Code: 
  - Terraform provisions resources for QA (EC2, S3).
  - Kubernetes (EKS) manages UAT and Prod environments.
- Blue/Green Deployments: Implemented in production using ArgoCD and Argo Rollouts for zero-downtime releases.
- GitOps Workflow: All environment states managed through GitHub repos, automated pipelines and shell scripts.

## Technologies Used

- Backend Services: FastAPI (Python)
- Infrastructure:
  - AWS (ECR, EC2, S3, Route 53, SSM, Secrets Manager)
  - Kubernetes (EKS)
  - Terraform
  - Helm + ArgoCD
  - cert-manager + Let’s Encrypt
- CI/CD:
  - GitHub Actions
  - Shell Scripting
- Security:
  - SSL/TLS with cert-manager
  - DNS automation via Route 53

## QA Automation

- Terraform spins up an ephemeral EC2 instance for QA.
- EC2 pulls test scripts from S3 and runs smoke tests on the latest Docker images.
- If tests pass, images are tagged and promoted to UAT.

## UAT and Production

- UAT and Prod are both deployed to EKS.
- Blue/Green deployment strategy is enabled via Argo Rollouts for Prod.
- cert-manager automatically issues and renews HTTPS certificates using Let’s Encrypt, with DNS validation handled by Route 53.

## Deployment Workflow

1. Detect changes in service code nightly.
2. Build Docker images and tag with semantic version.
3. Push to ECR.
4. Run Terraform plan/apply to spin up QA environment.
5. Pull images and set up smoke tests via scripts stored in S3.
6. Execute smoke tests via EC2 instance.
7. On success, promote to UAT.
8. Spin up UAT via scripts to perform tests.
9. On success promote and deploy to Prod via scripts and use Argo Rollouts for blue/green.