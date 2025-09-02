#!/bin/bash

# Network Management Script
# Comprehensive utility for managing Hyperledger Fabric peer network operations

set -e

# Configuration
NETWORK_DIR="/root/hyperledger-fabric-network"
SCRIPTS_DIR="$NETWORK_DIR/peers/scripts"
COMPOSE_FILE="$NETWORK_DIR/docker-compose.yaml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

header() {
    echo -e "${PURPLE}[$(date +'%Y-%m-%d %H:%M:%S')] === $1 ===${NC}"
}

# Start network
start_network() {
    header "Starting Hyperledger Fabric Network"
    
    cd "$NETWORK_DIR"
    
    log "Starting all peer services..."
    docker-compose up -d
    
    log "Waiting for services to initialize..."
    sleep 15
    
    log "Checking service status..."
    docker-compose ps
    
    info "✓ Network started successfully"
}

# Stop network
stop_network() {
    header "Stopping Hyperledger Fabric Network"
    
    cd "$NETWORK_DIR"
    
    log "Stopping all peer services..."
    docker-compose down
    
    info "✓ Network stopped successfully"
}

# Restart network
restart_network() {
    header "Restarting Hyperledger Fabric Network"
    
    cd "$NETWORK_DIR"
    
    log "Stopping services..."
    docker-compose down
    
    log "Starting services..."
    docker-compose up -d
    
    log "Waiting for services to initialize..."
    sleep 15
    
    log "Checking service status..."
    docker-compose ps
    
    info "✓ Network restarted successfully"
}

# Clean network (remove containers and volumes)
clean_network() {
    header "Cleaning Hyperledger Fabric Network"
    
    warn "This will remove all containers, networks, and volumes!"
    read -p "Are you sure you want to continue? [y/N]: " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Clean operation cancelled"
        return 0
    fi
    
    cd "$NETWORK_DIR"
    
    log "Stopping and removing containers..."
    docker-compose down -v --remove-orphans
    
    log "Removing fabric-related Docker objects..."
    docker system prune -f --filter "label=com.docker.compose.project"
    
    # Remove peer data (with confirmation)
    if [ -d "peer-data" ]; then
        warn "Remove peer data directory as well?"
        read -p "This will delete all blockchain data! [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf peer-data
            info "✓ Peer data removed"
        fi
    fi
    
    info "✓ Network cleaned successfully"
}

# Show network status
show_status() {
    header "Hyperledger Fabric Network Status"
    
    cd "$NETWORK_DIR"
    
    # Container status
    log "Container Status:"
    docker-compose ps
    echo
    
    # Resource usage
    log "Resource Usage:"
    docker system df
    echo
    
    # Network information
    log "Network Information:"
    docker network ls | grep -E "(fabric|peer)" || info "No fabric networks found"
    echo
    
    # Volume information
    log "Volume Information:"
    docker volume ls | grep -E "(fabric|peer)" || info "No fabric volumes found"
    echo
    
    # Port usage
    log "Port Usage:"
    netstat -tuln | grep -E ":(7051|7052|7053|7054|8051|8052|8053|8054|9051|9052|9053|9054)" || info "No fabric ports in use"
    echo
}

# Show logs
show_logs() {
    local service="$1"
    local tail_lines="${2:-100}"
    
    cd "$NETWORK_DIR"
    
    if [ -n "$service" ]; then
        header "Logs for service: $service"
        docker-compose logs --tail="$tail_lines" --follow "$service"
    else
        header "Logs for all services"
        docker-compose logs --tail="$tail_lines" --follow
    fi
}

# Execute script utilities
run_script() {
    local script_name="$1"
    shift
    local script_args="$@"
    
    local script_path="$SCRIPTS_DIR/$script_name"
    
    if [ ! -f "$script_path" ]; then
        error "Script not found: $script_path"
    fi
    
    if [ ! -x "$script_path" ]; then
        error "Script is not executable: $script_path"
    fi
    
    header "Running $script_name"
    "$script_path" $script_args
}

# Show available scripts
list_scripts() {
    header "Available Scripts"
    
    if [ ! -d "$SCRIPTS_DIR" ]; then
        warn "Scripts directory not found: $SCRIPTS_DIR"
        return 1
    fi
    
    echo
    printf "%-25s %-50s\n" "SCRIPT" "DESCRIPTION"
    printf "%-25s %-50s\n" "------" "-----------"
    
    for script in "$SCRIPTS_DIR"/*.sh; do
        if [ -f "$script" ]; then
            local script_name=$(basename "$script")
            local description=$(grep -m1 "^# .*Script$" "$script" | sed 's/^# //' || echo "No description available")
            printf "%-25s %-50s\n" "$script_name" "$description"
        fi
    done
    
    echo
    info "Run scripts with: $0 script <script-name> [args...]"
    echo
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Network Commands:
    start           Start the Hyperledger Fabric network
    stop            Stop the network
    restart         Restart the network
    clean           Clean network (remove containers and volumes)
    status          Show network status
    logs [SERVICE]  Show logs (optionally for specific service)

Script Commands:
    scripts         List available scripts
    script NAME     Run a specific script
    deploy          Quick deploy (alias for deploy-peers.sh)
    health          Quick health check (alias for health-check.sh)
    backup          Quick backup (alias for backup-ledger.sh)
    certs           Quick certificate check (alias for renew-certificates.sh check)

Examples:
    $0 start                    Start the network
    $0 status                   Show network status
    $0 logs peer0.org1         Show logs for specific peer
    $0 script health-check.sh   Run health check script
    $0 deploy                   Deploy peers
    $0 backup                   Create full backup
    $0 certs                    Check certificate expiration

EOF
}

# Main execution
main() {
    local command="${1:-status}"
    
    case "$command" in
        "start")
            start_network
            ;;
        "stop")
            stop_network
            ;;
        "restart")
            restart_network
            ;;
        "clean")
            clean_network
            ;;
        "status")
            show_status
            ;;
        "logs")
            show_logs "$2" "$3"
            ;;
        "scripts")
            list_scripts
            ;;
        "script")
            run_script "$2" "${@:3}"
            ;;
        "deploy")
            run_script "deploy-peers.sh" "${@:2}"
            ;;
        "health")
            run_script "health-check.sh" "${@:2}"
            ;;
        "backup")
            run_script "backup-ledger.sh" "${@:2}"
            ;;
        "certs")
            run_script "renew-certificates.sh" "check" "${@:2}"
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
