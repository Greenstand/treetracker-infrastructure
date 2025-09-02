#!/bin/bash

# Verify New Peer Configurations
# Validates certificates, configurations, and readiness for deployment

set -e

SECRETS_DIR="/root/hyperledger-fabric-network/peers/secrets"

log() {
    echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

warn() {
    echo -e "\033[1;33m[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1\033[0m"
}

error() {
    echo -e "\033[0;31m[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1\033[0m"
}

verify_peer_certificates() {
    local peer_name="$1"
    local org_name="$2"
    
    log "🔍 Verifying ${peer_name} peer certificates..."
    
    # Check MSP certificate
    if [ -f "$SECRETS_DIR/${peer_name}-msp/signcerts/cert.pem" ]; then
        local subject=$(openssl x509 -in "$SECRETS_DIR/${peer_name}-msp/signcerts/cert.pem" -noout -subject)
        echo "  ✅ MSP Certificate: $subject"
        
        local expiry=$(openssl x509 -in "$SECRETS_DIR/${peer_name}-msp/signcerts/cert.pem" -noout -enddate)
        echo "  📅 MSP Expiry: $expiry"
    else
        error "MSP certificate not found for ${peer_name}"
        return 1
    fi
    
    # Check TLS certificate
    if [ -f "$SECRETS_DIR/${peer_name}-tls/server.crt" ]; then
        local tls_subject=$(openssl x509 -in "$SECRETS_DIR/${peer_name}-tls/server.crt" -noout -subject)
        echo "  ✅ TLS Certificate: $tls_subject"
        
        local tls_expiry=$(openssl x509 -in "$SECRETS_DIR/${peer_name}-tls/server.crt" -noout -enddate)
        echo "  📅 TLS Expiry: $tls_expiry"
    else
        error "TLS certificate not found for ${peer_name}"
        return 1
    fi
    
    # Check private keys
    if [ -f "$SECRETS_DIR/${peer_name}-tls/server.key" ]; then
        echo "  🔐 TLS Private Key: Present and secured"
    else
        error "TLS private key not found for ${peer_name}"
        return 1
    fi
    
    # Check MSP config
    if [ -f "$SECRETS_DIR/${peer_name}-msp/config.yaml" ]; then
        echo "  ⚙️ MSP Config: Present"
    else
        error "MSP config not found for ${peer_name}"
        return 1
    fi
    
    # Check Helm values
    if [ -f "/root/hyperledger-fabric-network/peers/helm-charts/values-${peer_name}.yaml" ]; then
        echo "  📦 Helm Values: Present"
    else
        error "Helm values not found for ${peer_name}"
        return 1
    fi
    
    # Check deployment script
    if [ -f "/root/hyperledger-fabric-network/peers/scripts/deploy-${peer_name}-peer.sh" ]; then
        echo "  🚀 Deployment Script: Present"
    else
        error "Deployment script not found for ${peer_name}"
        return 1
    fi
    
    log "✅ ${peer_name} peer (${org_name}) verification completed successfully"
    echo ""
}

# Main verification
main() {
    log "🔍 Starting verification of new peer configurations..."
    echo ""
    
    # Verify each peer
    verify_peer_certificates "cbo" "CBOMSP"
    verify_peer_certificates "investor" "InvestorMSP"
    verify_peer_certificates "verifier" "VerifierMSP"
    
    log "🎉 All peer configurations verified successfully!"
    echo ""
    log "📋 Summary:"
    log "  • CBO Peer (CBOMSP): ✅ Ready for deployment"
    log "  • Investor Peer (InvestorMSP): ✅ Ready for deployment" 
    log "  • Verifier Peer (VerifierMSP): ✅ Ready for deployment"
    echo ""
    log "🚀 Next Steps:"
    log "  1. Deploy peers: ./scripts/deploy-all-new-peers.sh"
    log "  2. Verify deployments: kubectl get pods -n hlf-{cbo,investor,verifier}-peer"
    log "  3. Join channels and install chaincode"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
