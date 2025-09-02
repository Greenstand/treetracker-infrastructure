#!/bin/bash

# Generate CBO, Investor, and Verifier Peer Certificates
# Automates certificate generation for new peer organizations

set -e

# Configuration
NAMESPACE="hlf-ca"
FABRIC_CA_CLIENT_POD="fabric-ca-client-0"
PEERS_DIR="/root/hyperledger-fabric-network/peers"
SECRETS_DIR="$PEERS_DIR/secrets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Peer configurations
declare -A PEER_CONFIGS=(
    ["cbo"]="cbocapw"
    ["investor"]="investorcapw" 
    ["verifier"]="verifiercapw"
)

declare -A PEER_MSPS=(
    ["cbo"]="CBOMSP"
    ["investor"]="InvestorMSP"
    ["verifier"]="VerifierMSP"
)

# Register and enroll peer with CA
generate_peer_certificates() {
    local peer_name="$1"
    local ca_password="$2"
    local msp_id="$3"
    local ca_name="${peer_name}-ca"
    local ca_host="${ca_name}.hlf-ca.svc.cluster.local:7054"
    
    log "Generating certificates for ${peer_name} peer..."
    
    # Create directories
    mkdir -p "$SECRETS_DIR/${peer_name}-msp/cacerts"
    mkdir -p "$SECRETS_DIR/${peer_name}-msp/signcerts"
    mkdir -p "$SECRETS_DIR/${peer_name}-msp/keystore"
    mkdir -p "$SECRETS_DIR/${peer_name}-tls/cacerts"
    mkdir -p "$SECRETS_DIR/${peer_name}-tls/signcerts"
    mkdir -p "$SECRETS_DIR/${peer_name}-tls/keystore"
    mkdir -p "$SECRETS_DIR/${peer_name}-tls/tlscacerts"
    
    # Register peer identity with CA
    log "Registering ${peer_name} peer identity..."
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- \
        fabric-ca-client register \
            --id.name "peer0.${peer_name}" \
            --id.secret "peer0${peer_name}pw" \
            --id.type peer \
            --id.attrs "hf.Registrar.Roles=peer" \
            --tls.certfiles "/data/hyperledger/fabric-ca-client/${ca_name}/tls-cert.pem" \
            --url "https://${ca_host}" \
            --mspdir "/data/hyperledger/fabric-ca-client/${ca_name}/msp" || true
    
    # Enroll peer for MSP
    log "Enrolling ${peer_name} peer for MSP..."
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- \
        fabric-ca-client enroll \
            --url "https://peer0.${peer_name}:peer0${peer_name}pw@${ca_host}" \
            --tls.certfiles "/data/hyperledger/fabric-ca-client/${ca_name}/tls-cert.pem" \
            --mspdir "/tmp/${peer_name}-msp"
    
    # Enroll peer for TLS
    log "Enrolling ${peer_name} peer for TLS..."
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- \
        fabric-ca-client enroll \
            --url "https://peer0.${peer_name}:peer0${peer_name}pw@${ca_host}" \
            --tls.certfiles "/data/hyperledger/fabric-ca-client/${ca_name}/tls-cert.pem" \
            --enrollment.profile "tls" \
            --csr.hosts "peer0.${peer_name},peer0.${peer_name}.${peer_name},localhost" \
            --mspdir "/tmp/${peer_name}-tls"
    
    # Copy certificates from CA client pod using tar
    log "Copying certificates for ${peer_name} peer..."
    
    # Create tar archive of MSP certificates in the pod
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- tar -czf "/tmp/${peer_name}-msp.tar.gz" -C "/tmp" "${peer_name}-msp"
    
    # Copy tar archive to local machine
    kubectl cp "$NAMESPACE/$FABRIC_CA_CLIENT_POD:/tmp/${peer_name}-msp.tar.gz" "/tmp/${peer_name}-msp.tar.gz"
    
    # Extract MSP certificates
    tar -xzf "/tmp/${peer_name}-msp.tar.gz" -C "/tmp"
    cp -r "/tmp/${peer_name}-msp/"* "$SECRETS_DIR/${peer_name}-msp/"
    
    # Create tar archive of TLS certificates in the pod
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- tar -czf "/tmp/${peer_name}-tls.tar.gz" -C "/tmp" "${peer_name}-tls"
    
    # Copy tar archive to local machine
    kubectl cp "$NAMESPACE/$FABRIC_CA_CLIENT_POD:/tmp/${peer_name}-tls.tar.gz" "/tmp/${peer_name}-tls.tar.gz"
    
    # Extract TLS certificates
    tar -xzf "/tmp/${peer_name}-tls.tar.gz" -C "/tmp"
    cp -r "/tmp/${peer_name}-tls/"* "$SECRETS_DIR/${peer_name}-tls/"
    
    # Copy TLS certificates to standard names
    cp "$SECRETS_DIR/${peer_name}-tls/signcerts/cert.pem" "$SECRETS_DIR/${peer_name}-tls/server.crt"
    
    # Find and copy the first TLS private key
    tls_key=$(ls "$SECRETS_DIR/${peer_name}-tls/keystore/"*_sk 2>/dev/null | head -1)
    if [ -n "$tls_key" ]; then
        cp "$tls_key" "$SECRETS_DIR/${peer_name}-tls/server.key"
    fi
    
    cp "$SECRETS_DIR/${peer_name}-tls/tlscacerts/"*.pem "$SECRETS_DIR/${peer_name}-tls/ca.crt"
    
    # Set proper permissions
    chmod 600 "$SECRETS_DIR/${peer_name}-msp/keystore/"* || true
    chmod 600 "$SECRETS_DIR/${peer_name}-tls/keystore/"* || true
    chmod 600 "$SECRETS_DIR/${peer_name}-tls/server.key" || true
    
    log "Certificates generated successfully for ${peer_name} peer"
}

# Generate MSP config.yaml
generate_msp_config() {
    local peer_name="$1"
    local ca_cert_name="${peer_name}-ca-hlf-ca-svc-cluster-local-7054.pem"
    
    cat > "$SECRETS_DIR/${peer_name}-msp/config.yaml" << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:  { OrganizationalUnitIdentifier: client,  Certificate: cacerts/${ca_cert_name} }
  PeerOUIdentifier:    { OrganizationalUnitIdentifier: peer,    Certificate: cacerts/${ca_cert_name} }
  AdminOUIdentifier:   { OrganizationalUnitIdentifier: admin,   Certificate: cacerts/${ca_cert_name} }
  OrdererOUIdentifier: { OrganizationalUnitIdentifier: orderer, Certificate: cacerts/${ca_cert_name} }
EOF
    
    log "MSP config generated for ${peer_name}"
}

# Main execution
main() {
    log "Starting certificate generation for CBO, Investor, and Verifier peers..."
    
    # Check if fabric-ca-client pod is available
    if ! kubectl get pod -n $NAMESPACE $FABRIC_CA_CLIENT_POD > /dev/null 2>&1; then
        error "fabric-ca-client pod not found in namespace $NAMESPACE"
    fi
    
    # Generate certificates for each peer
    for peer in "${!PEER_CONFIGS[@]}"; do
        log "Processing $peer peer..."
        generate_peer_certificates "$peer" "${PEER_CONFIGS[$peer]}" "${PEER_MSPS[$peer]}"
        generate_msp_config "$peer"
    done
    
    log "✅ All peer certificates generated successfully!"
    log "Next steps:"
    log "1. Update Helm values.yaml to include the new peers"
    log "2. Deploy the peers using helm upgrade"
    log "3. Verify peer connectivity and join channels"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
