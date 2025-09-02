#!/bin/bash

# Deploy Investor Peer to Kubernetes
set -e

NAMESPACE="hlf-investor-peer"
HELM_CHART_DIR="/root/hyperledger-fabric-network/peers/helm-charts"
SECRETS_DIR="/root/hyperledger-fabric-network/peers/secrets"

log() {
    echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

# Create namespace
log "Creating namespace ${NAMESPACE}..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Create Kubernetes secrets for MSP and TLS
log "Creating MSP secret for Investor peer..."
kubectl create secret generic peer0-investor-msp \
    --from-file="$SECRETS_DIR/investor-msp/" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

log "Creating TLS secret for Investor peer..."
kubectl create secret generic peer0-investor-tls \
    --from-file="$SECRETS_DIR/investor-tls/" \
    --namespace=$NAMESPACE \
    --dry-run=client -o yaml | kubectl apply -f -

# Deploy peer using Helm
log "Deploying Investor peer using Helm..."
helm upgrade --install investor-peer $HELM_CHART_DIR \
    --namespace=$NAMESPACE \
    --values=$HELM_CHART_DIR/values-investor.yaml \
    --wait

log "✅ Investor peer deployed successfully!"
log "📋 Peer service: peer0-investor.${NAMESPACE}.svc.cluster.local:7051"
log "📊 Operations endpoint: peer0-investor.${NAMESPACE}.svc.cluster.local:9443"
log "📈 Metrics endpoint: peer0-investor.${NAMESPACE}.svc.cluster.local:9444"
