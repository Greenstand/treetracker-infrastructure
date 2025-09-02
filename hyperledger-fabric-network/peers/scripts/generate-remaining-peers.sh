#!/bin/bash

# Generate CBO and Verifier Peer Certificates
set -e

NAMESPACE="hlf-ca"
FABRIC_CA_CLIENT_POD="fabric-ca-client-0"
SECRETS_DIR="/root/hyperledger-fabric-network/peers/secrets"

log() {
    echo -e "\033[0;32m[$(date +'%Y-%m-%d %H:%M:%S')] $1\033[0m"
}

generate_peer() {
    local peer_name="$1"
    local ca_name="${peer_name}-ca"
    local ca_host="${ca_name}.hlf-ca.svc.cluster.local:7054"
    
    log "Generating certificates for ${peer_name} peer..."
    
    # Create directories
    mkdir -p "$SECRETS_DIR/${peer_name}-msp/"{cacerts,signcerts,keystore}
    mkdir -p "$SECRETS_DIR/${peer_name}-tls/"{cacerts,signcerts,keystore,tlscacerts}
    
    # Register and enroll for MSP
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- \
        fabric-ca-client register \
            --id.name "peer0.${peer_name}" \
            --id.secret "peer0${peer_name}pw" \
            --id.type peer \
            --tls.certfiles "/data/hyperledger/fabric-ca-client/${ca_name}/tls-cert.pem" \
            --url "https://${ca_host}" \
            --mspdir "/data/hyperledger/fabric-ca-client/${ca_name}/msp" || true
    
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- \
        fabric-ca-client enroll \
            --url "https://peer0.${peer_name}:peer0${peer_name}pw@${ca_host}" \
            --tls.certfiles "/data/hyperledger/fabric-ca-client/${ca_name}/tls-cert.pem" \
            --mspdir "/tmp/${peer_name}-msp"
    
    # Register and enroll for TLS
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- \
        fabric-ca-client enroll \
            --url "https://peer0.${peer_name}:peer0${peer_name}pw@${ca_host}" \
            --tls.certfiles "/data/hyperledger/fabric-ca-client/${ca_name}/tls-cert.pem" \
            --enrollment.profile "tls" \
            --csr.hosts "peer0.${peer_name},peer0.${peer_name}.${peer_name},localhost" \
            --mspdir "/tmp/${peer_name}-tls"
    
    # Copy certificates using tar
    kubectl exec -n $NAMESPACE $FABRIC_CA_CLIENT_POD -- tar -czf "/tmp/${peer_name}-all.tar.gz" -C "/tmp" "${peer_name}-msp" "${peer_name}-tls"
    kubectl cp "$NAMESPACE/$FABRIC_CA_CLIENT_POD:/tmp/${peer_name}-all.tar.gz" "/tmp/${peer_name}-all.tar.gz"
    tar -xzf "/tmp/${peer_name}-all.tar.gz" -C "/tmp"
    
    # Copy to final locations
    cp -r "/tmp/${peer_name}-msp/"* "$SECRETS_DIR/${peer_name}-msp/"
    cp -r "/tmp/${peer_name}-tls/"* "$SECRETS_DIR/${peer_name}-tls/"
    
    # Create standard TLS files
    cp "$SECRETS_DIR/${peer_name}-tls/signcerts/cert.pem" "$SECRETS_DIR/${peer_name}-tls/server.crt"
    cp "$SECRETS_DIR/${peer_name}-tls/tlscacerts/"*.pem "$SECRETS_DIR/${peer_name}-tls/ca.crt"
    
    # Copy first private key
    first_key=$(ls "$SECRETS_DIR/${peer_name}-tls/keystore/"*_sk | head -1)
    cp "$first_key" "$SECRETS_DIR/${peer_name}-tls/server.key"
    
    # Set permissions
    chmod 600 "$SECRETS_DIR/${peer_name}-msp/keystore/"*
    chmod 600 "$SECRETS_DIR/${peer_name}-tls/keystore/"*
    chmod 600 "$SECRETS_DIR/${peer_name}-tls/server.key"
    
    # Create MSP config
    cat > "$SECRETS_DIR/${peer_name}-msp/config.yaml" << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:  { OrganizationalUnitIdentifier: client,  Certificate: cacerts/${peer_name}-ca-hlf-ca-svc-cluster-local-7054.pem }
  PeerOUIdentifier:    { OrganizationalUnitIdentifier: peer,    Certificate: cacerts/${peer_name}-ca-hlf-ca-svc-cluster-local-7054.pem }
  AdminOUIdentifier:   { OrganizationalUnitIdentifier: admin,   Certificate: cacerts/${peer_name}-ca-hlf-ca-svc-cluster-local-7054.pem }
  OrdererOUIdentifier: { OrganizationalUnitIdentifier: orderer, Certificate: cacerts/${peer_name}-ca-hlf-ca-svc-cluster-local-7054.pem }
EOF
    
    log "✅ ${peer_name} peer certificates generated successfully"
}

# Generate CBO and Verifier peers
generate_peer "cbo"
generate_peer "verifier"

log "✅ All remaining peer certificates generated!"
