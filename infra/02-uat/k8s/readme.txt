LOCAL

run login.sh (after setting aws creds)

ex.

kubectl apply -f email-service.yaml

should get something like:

deployment.apps/email-service created
service/email-service created

and to test:

kubectl port-forward svc/email-service 8000:8000

ALSO BTW IF YOU USE SECRETS:

kubectl create secret generic db-connection-secret \
  --from-literal=POSTGRES_URL=postgresql://user:pass@host:5432/dbname

clear all:

kubectl delete all --all

ingress controller:

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.5/deploy/static/provider/cloud/deploy.yaml