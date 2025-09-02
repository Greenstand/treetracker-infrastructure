#!/bin/bash

# Certificate Renewal Script
# Automates certificate renewal for Hyperledger Fabric peers

set -e

# Configuration
NETWORK_DIR="/root/hyperledger-fabric-network"
CRYPTO_CONFIG_DIR="$NETWORK_DIR/crypto-config"
BACKUP_DIR="$NETWORK_DIR/cert-backups"
CRYPTOGEN_TOOL="cryptogen"

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

# Check certificate expiration
check_cert_expiration() {
    local cert_file="$1"
    local days_threshold="${2:-30}"
    
    if [ ! -f "$cert_file" ]; then
        warn "Certificate file not found: $cert_file"
        return 1
    fi
    
    local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    local expiry_epoch=$(date -d "$expiry_date" +%s)
    local current_epoch=$(date +%s)
    local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    log "Certificate $cert_file expires in $days_until_expiry days"
    
    if [ $days_until_expiry -le $days_threshold ]; then
        warn "Certificate $cert_file expires in $days_until_expiry days (threshold: $days_threshold)"
        return 0
    fi
    
    return 1
}

# Backup existing certificates
backup_certificates() {
    log "Backing up existing certificates..."
    
    mkdir -p "$BACKUP_DIR"
    local backup_timestamp=$(date +'%Y%m%d_%H%M%S')
    local backup_path="$BACKUP_DIR/crypto-config_$backup_timestamp"
    
    if [ -d "$CRYPTO_CONFIG_DIR" ]; then
        cp -r "$CRYPTO_CONFIG_DIR" "$backup_path"
        log "Certificates backed up to: $backup_path"
    else
        warn "Crypto config directory not found: $CRYPTO_CONFIG_DIR"
    fi
}

# Generate new certificates
generate_certificates() {
    log "Generating new certificates..."
    
    cd "$NETWORK_DIR"
    
    # Check if crypto-config.yaml exists
    if [ ! -f "crypto-config.yaml" ]; then
        error "crypto-config.yaml not found in $NETWORK_DIR"
    fi
    
    # Remove old certificates
    if [ -d "$CRYPTO_CONFIG_DIR" ]; then
        rm -rf "$CRYPTO_CONFIG_DIR"
    fi
    
    # Generate new certificates
    $CRYPTOGEN_TOOL generate --config=crypto-config.yaml
    
    log "New certificates generated successfully"
}

# Update peer containers with new certificates
update_peer_containers() {
    log "Updating peer containers with new certificates..."
    
    cd "$NETWORK_DIR"
    
    # Stop existing containers
    log "Stopping peer containers..."
    docker-compose down
    
    # Start containers with new certificates
    log "Starting peer containers with new certificates..."
    docker-compose up -d
    
    # Wait for services to be ready
    sleep 15
    
    # Verify containers are running
    docker-compose ps
    
    log "Peer containers updated successfully"
}

# Check certificate status across the network
check_all_certificates() {
    log "Checking all peer certificates..."
    
    local days_threshold="${1:-30}"
    local renewal_needed=false
    
    if [ -d "$CRYPTO_CONFIG_DIR" ]; then
        # Find all certificate files
        find "$CRYPTO_CONFIG_DIR" -name "*.pem" -type f | while read cert_file; do
            if check_cert_expiration "$cert_file" "$days_threshold"; then
                renewal_needed=true
            fi
        done
    else
        warn "Crypto config directory not found: $CRYPTO_CONFIG_DIR"
    fi
    
    return 0
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    check [DAYS]    Check certificate expiration (default: 30 days threshold)
    renew           Renew all certificates
    backup          Backup existing certificates only
    help            Show this help message

Examples:
    $0 check 15     Check certificates expiring within 15 days
    $0 renew        Renew all certificates
    $0 backup       Backup certificates without renewal

EOF
}

# Main execution
main() {
    local command="${1:-check}"
    
    case "$command" in
        "check")
            local threshold="${2:-30}"
            log "Checking certificate expiration (threshold: $threshold days)"
            check_all_certificates "$threshold"
            ;;
        "renew")
            log "Starting certificate renewal process"
            backup_certificates
            generate_certificates
            update_peer_containers
            log "Certificate renewal completed"
            ;;
        "backup")
            backup_certificates
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            error "Unknown command: $command. Use '$0 help' for usage information."
            ;;
    esac
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
