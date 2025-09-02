#!/bin/bash

# Deploy Peers Script
# Automated peer deployment for Hyperledger Fabric network

set -e

# Configuration
NETWORK_DIR="/root/hyperledger-fabric-network"
PEERS_DIR="$NETWORK_DIR/peers"
COMPOSE_FILE="$NETWORK_DIR/docker-compose.yaml"

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

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed or not in PATH"
    fi
    
    if [ ! -f "$COMPOSE_FILE" ]; then
        warn "Docker Compose file not found at $COMPOSE_FILE"
    fi
    
    log "Prerequisites check completed"
}

# Deploy peers
deploy_peers() {
    log "Starting peer deployment..."
    
    cd "$NETWORK_DIR"
    
    # Pull latest images
    log "Pulling latest Hyperledger Fabric images..."
    docker-compose pull
    
    # Start peer services
    log "Starting peer containers..."
    docker-compose up -d
    
    # Wait for services to be ready
    log "Waiting for peer services to be ready..."
    sleep 10
    
    # Check peer status
    log "Checking peer container status..."
    docker-compose ps
    
    log "Peer deployment completed successfully"
}

# Main execution
main() {
    log "Starting Hyperledger Fabric peer deployment"
    
    check_prerequisites
    deploy_peers
    
    log "Deployment process completed"
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
