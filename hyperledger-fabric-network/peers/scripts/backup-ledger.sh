#!/bin/bash

# Backup Ledger Script
# Creates backups of Hyperledger Fabric blockchain data and peer configurations

set -e

# Configuration
NETWORK_DIR="/root/hyperledger-fabric-network"
BACKUP_BASE_DIR="$NETWORK_DIR/backups"
PEER_DATA_DIR="$NETWORK_DIR/peer-data"
CRYPTO_CONFIG_DIR="$NETWORK_DIR/crypto-config"
COMPOSE_FILE="$NETWORK_DIR/docker-compose.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Create backup directory structure
create_backup_structure() {
    local backup_timestamp="$1"
    local backup_dir="$BACKUP_BASE_DIR/$backup_timestamp"
    
    mkdir -p "$backup_dir"/{ledger-data,crypto-config,configurations,logs}
    echo "$backup_dir"
}

# Backup peer ledger data
backup_ledger_data() {
    local backup_dir="$1"
    log "Backing up peer ledger data..."
    
    # Stop containers to ensure consistent backup
    cd "$NETWORK_DIR"
    log "Stopping peer containers for consistent backup..."
    docker-compose stop
    
    # Backup peer data volumes
    if [ -d "$PEER_DATA_DIR" ]; then
        log "Copying peer data directory..."
        cp -r "$PEER_DATA_DIR" "$backup_dir/ledger-data/"
        info "✓ Peer data backed up"
    else
        warn "Peer data directory not found: $PEER_DATA_DIR"
    fi
    
    # Backup Docker volumes (if any)
    local volumes=$(docker volume ls -q | grep -E "(peer|fabric)" 2>/dev/null || true)
    if [ -n "$volumes" ]; then
        log "Backing up Docker volumes..."
        mkdir -p "$backup_dir/ledger-data/volumes"
        for volume in $volumes; do
            info "Backing up volume: $volume"
            docker run --rm -v "$volume":/source -v "$backup_dir/ledger-data/volumes":/backup alpine tar czf "/backup/$volume.tar.gz" -C /source .
        done
        info "✓ Docker volumes backed up"
    fi
    
    # Restart containers
    log "Restarting peer containers..."
    docker-compose up -d
    sleep 10
}

# Backup crypto materials
backup_crypto_config() {
    local backup_dir="$1"
    log "Backing up crypto configuration..."
    
    if [ -d "$CRYPTO_CONFIG_DIR" ]; then
        cp -r "$CRYPTO_CONFIG_DIR" "$backup_dir/crypto-config/"
        info "✓ Crypto configuration backed up"
    else
        warn "Crypto config directory not found: $CRYPTO_CONFIG_DIR"
    fi
}

# Backup network configurations
backup_configurations() {
    local backup_dir="$1"
    log "Backing up network configurations..."
    
    cd "$NETWORK_DIR"
    
    # Backup compose files
    find . -name "docker-compose*.yaml" -o -name "docker-compose*.yml" -exec cp {} "$backup_dir/configurations/" \;
    
    # Backup config files
    find . -name "*.yaml" -o -name "*.yml" -o -name "*.json" -maxdepth 2 -exec cp {} "$backup_dir/configurations/" \;
    
    # Backup genesis block and channel artifacts
    if [ -d "channel-artifacts" ]; then
        cp -r channel-artifacts "$backup_dir/configurations/"
    fi
    
    if [ -d "configtx" ]; then
        cp -r configtx "$backup_dir/configurations/"
    fi
    
    info "✓ Network configurations backed up"
}

# Backup container logs
backup_logs() {
    local backup_dir="$1"
    log "Backing up container logs..."
    
    cd "$NETWORK_DIR"
    
    # Get all container logs
    local containers=$(docker-compose ps -q 2>/dev/null || true)
    if [ -n "$containers" ]; then
        for container_id in $containers; do
            local container_name=$(docker inspect --format='{{.Name}}' "$container_id" | sed 's/^\/*//')
            info "Backing up logs for: $container_name"
            docker logs "$container_id" > "$backup_dir/logs/$container_name.log" 2>&1 || warn "Failed to backup logs for $container_name"
        done
        info "✓ Container logs backed up"
    else
        warn "No containers found to backup logs from"
    fi
}

# Compress backup
compress_backup() {
    local backup_dir="$1"
    local backup_timestamp="$(basename "$backup_dir")"
    
    log "Compressing backup..."
    
    cd "$BACKUP_BASE_DIR"
    tar -czf "$backup_timestamp.tar.gz" "$backup_timestamp"
    
    # Calculate sizes
    local original_size=$(du -sh "$backup_timestamp" | cut -f1)
    local compressed_size=$(du -sh "$backup_timestamp.tar.gz" | cut -f1)
    
    info "✓ Backup compressed: $original_size → $compressed_size"
    info "Compressed backup: $BACKUP_BASE_DIR/$backup_timestamp.tar.gz"
    
    # Optionally remove uncompressed backup
    read -p "Remove uncompressed backup directory? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$backup_timestamp"
        info "✓ Uncompressed backup removed"
    fi
}

# List existing backups
list_backups() {
    log "Listing existing backups..."
    
    if [ ! -d "$BACKUP_BASE_DIR" ]; then
        info "No backup directory found"
        return 0
    fi
    
    cd "$BACKUP_BASE_DIR"
    
    echo
    printf "%-20s %-10s %-30s\n" "BACKUP" "SIZE" "CREATED"
    printf "%-20s %-10s %-30s\n" "------" "----" "-------"
    
    for backup in *.tar.gz 2>/dev/null; do
        if [ -f "$backup" ]; then
            local size=$(du -sh "$backup" | cut -f1)
            local created=$(stat -c %y "$backup" | cut -d' ' -f1,2 | cut -d'.' -f1)
            printf "%-20s %-10s %-30s\n" "$backup" "$size" "$created"
        fi
    done
    
    echo
}

# Restore from backup
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        error "Backup file not specified. Usage: $0 restore <backup-file>"
    fi
    
    if [ ! -f "$BACKUP_BASE_DIR/$backup_file" ]; then
        error "Backup file not found: $BACKUP_BASE_DIR/$backup_file"
    fi
    
    warn "This will replace current network data with backup data!"
    read -p "Are you sure you want to continue? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Restore cancelled"
        return 0
    fi
    
    log "Restoring from backup: $backup_file"
    
    # Stop containers
    cd "$NETWORK_DIR"
    docker-compose down
    
    # Extract backup
    cd "$BACKUP_BASE_DIR"
    tar -xzf "$backup_file"
    
    local backup_name=$(basename "$backup_file" .tar.gz)
    
    # Restore data
    if [ -d "$backup_name/ledger-data" ]; then
        log "Restoring ledger data..."
        rm -rf "$PEER_DATA_DIR"
        cp -r "$backup_name/ledger-data/peer-data" "$PEER_DATA_DIR" 2>/dev/null || true
    fi
    
    if [ -d "$backup_name/crypto-config" ]; then
        log "Restoring crypto configuration..."
        rm -rf "$CRYPTO_CONFIG_DIR"
        cp -r "$backup_name/crypto-config/crypto-config" "$CRYPTO_CONFIG_DIR" 2>/dev/null || true
    fi
    
    # Cleanup extracted backup
    rm -rf "$backup_name"
    
    # Restart network
    log "Restarting network..."
    cd "$NETWORK_DIR"
    docker-compose up -d
    
    log "Restore completed successfully"
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    full            Create full backup (ledger + crypto + configs + logs)
    ledger          Backup ledger data only
    crypto          Backup crypto materials only
    configs         Backup configurations only
    logs            Backup container logs only
    list            List existing backups
    restore FILE    Restore from backup file
    help            Show this help message

Examples:
    $0              Create full backup
    $0 full         Same as above
    $0 ledger       Backup only ledger data
    $0 list         Show all available backups
    $0 restore backup-20240901_143022.tar.gz

EOF
}

# Main execution
main() {
    local command="${1:-full}"
    local backup_timestamp=$(date +'%Y%m%d_%H%M%S')
    local backup_dir
    
    case "$command" in
        "full"|"")
            log "Starting full backup process"
            backup_dir=$(create_backup_structure "$backup_timestamp")
            backup_ledger_data "$backup_dir"
            backup_crypto_config "$backup_dir"
            backup_configurations "$backup_dir"
            backup_logs "$backup_dir"
            compress_backup "$backup_dir"
            log "Full backup completed: backup-$backup_timestamp.tar.gz"
            ;;
        "ledger")
            log "Starting ledger backup"
            backup_dir=$(create_backup_structure "$backup_timestamp")
            backup_ledger_data "$backup_dir"
            compress_backup "$backup_dir"
            ;;
        "crypto")
            log "Starting crypto backup"
            backup_dir=$(create_backup_structure "$backup_timestamp")
            backup_crypto_config "$backup_dir"
            compress_backup "$backup_dir"
            ;;
        "configs")
            log "Starting configuration backup"
            backup_dir=$(create_backup_structure "$backup_timestamp")
            backup_configurations "$backup_dir"
            compress_backup "$backup_dir"
            ;;
        "logs")
            log "Starting logs backup"
            backup_dir=$(create_backup_structure "$backup_timestamp")
            backup_logs "$backup_dir"
            compress_backup "$backup_dir"
            ;;
        "list")
            list_backups
            ;;
        "restore")
            restore_backup "$2"
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
