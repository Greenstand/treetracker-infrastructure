#!/bin/bash

# Deploy CBO Peer to Kubernetes
set -e

NAMESPACE="hlf-cbo-peer"
HELM_CHART_DIR="/root/hyperledger-fabric-network/peers/helm-charts"
SECRETS_DIR="/root/hyperledger-fabric-network/peers/secrets"

log() {
    echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

# Create namespace
log "Creating namespace ${NAMESPACE}..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create Kubernetes secrets for MSP and TLS
log "Creating MSP secret for CBO peer..."
kubectl create secret generic peer0-cbo-msp \
    --from-file="$SECRETS_DIR/cbo-msp/" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

log "Creating TLS secret for CBO peer..."
kubectl create secret generic peer0-cbo-tls \
    --from-file="$SECRETS_DIR/cbo-tls/" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy peer using Helm
log "Deploying CBO peer using Helm..."
helm upgrade --install cbo-peer $HELM_CHART_DIR \
    --namespace=$NAMESPACE \
    --values=$HELM_CHART_DIR/values-cbo.yaml \
    --wait

log "✅ CBO peer deployed successfully!"
log "📋 Peer service: peer0-cbo.${NAMESPACE}.svc.cluster.local:7051"
log "📊 Operations endpoint: peer0-cbo.${NAMESPACE}.svc.cluster.local:9443"
log "📈 Metrics endpoint: peer0-cbo.${NAMESPACE}.svc.cluster.local:9444"
