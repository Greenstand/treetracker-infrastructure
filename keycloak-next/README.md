# Keycloak Helm Deployment
## Overview

This repository contains configuration files for deploying Keycloak on Kubernetes using the official Bitnami Legacy Keycloak Helm chart.

Keycloak provides identity and access management (IAM) with support for Single Sign-On (SSO), OAuth2, OpenID Connect, and SAML.


# Prerequisites

Ensure the following are installed:

Kubernetes cluster (K8s v1.23+ recommended)

Helm v3+

kubectl configured to access your cluster

Bitnami Sealed Secrets

External database (PostgreSQL)


## Install Keycloak
```bash
helm install keycloak ./keycloak-next --namespace keycloak -f values.yaml
```

## Upgrade Release
```bash
helm upgrade keycloak ./keycloak-next --namespace keycloak -f values.yaml
```

## Uninstall Keycloak
```bash
helm uninstall keycloak --namespace keycloak
```


## Access Keycloak
```bash
export SERVICE_PORT=$(kubectl get --namespace keycloak -o jsonpath="{.spec.ports[?(@.name=='http')].port}" services keycloak)

kubectl port-forward --namespace keycloak svc/keycloak ${SERVICE_PORT}:${SERVICE_PORT} &
```


# Using Sealed Secrets

### Generate Secret:
```bash
kubectl create secret generic keycloak-secret \
  --from-literal=postgresql-password="YOUR_DB_PASSWORD" \
  --dry-run=client -o yaml > keycloak-secret.yaml
```

### Seal it:
```bash
kubeseal --format yaml < keycloak-secret.yaml > sealed-keycloak-secret.yaml
```
### Apply:
```bash
kubectl apply -f sealed-keycloak-secret.yaml
```