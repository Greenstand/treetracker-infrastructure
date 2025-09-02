#!/bin/bash

# Deploy All New Peers (CBO, Investor, Verifier) to Kubernetes
set -e

SCRIPT_DIR="/root/hyperledger-fabric-network/peers/scripts"

log() {
    echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

warn() {
    echo -e "\033[1;33m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

log "🚀 Starting deployment of all new peers..."
log "📋 Deploying: CBO Peer, Investor Peer, Verifier Peer"

# Deploy each peer
log "1️⃣ Deploying CBO Peer..."
$SCRIPT_DIR/deploy-cbo-peer.sh

log "2️⃣ Deploying Investor Peer..."
$SCRIPT_DIR/deploy-investor-peer.sh

log "3️⃣ Deploying Verifier Peer..."
$SCRIPT_DIR/deploy-verifier-peer.sh

log "✅ All peers deployed successfully!"

# Verification
log "🔍 Verifying deployments..."

log "Checking namespaces..."
kubectl get namespaces | grep hlf-.*-peer

log "Checking peer pods..."
kubectl get pods -n hlf-cbo-peer
kubectl get pods -n hlf-investor-peer  
kubectl get pods -n hlf-verifier-peer

log "Checking peer services..."
kubectl get services -n hlf-cbo-peer
kubectl get services -n hlf-investor-peer
kubectl get services -n hlf-verifier-peer

log "🎉 All new peers are ready!"
log ""
log "📊 Summary:"
log "  • CBO Peer:      peer0-cbo.hlf-cbo-peer.svc.cluster.local:7051"
log "  • Investor Peer: peer0-investor.hlf-investor-peer.svc.cluster.local:7051"
log "  • Verifier Peer: peer0-verifier.hlf-verifier-peer.svc.cluster.local:7051"
log ""
log "📋 Next steps:"
log "  1. Join peers to channels using peer CLI"
log "  2. Install and instantiate chaincode"
log "  3. Configure endorsement policies"
log "  4. Test cross-organization transactions"
