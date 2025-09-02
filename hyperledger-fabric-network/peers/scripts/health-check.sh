#!/bin/bash

# Health Check Script
# Monitors Hyperledger Fabric peer health and status

set -e

# Configuration
NETWORK_DIR="/root/hyperledger-fabric-network"
COMPOSE_FILE="$NETWORK_DIR/docker-compose.yaml"
LOG_DIR="$NETWORK_DIR/logs"

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
}

# Check Docker service status
check_docker_status() {
    log "Checking Docker service status..."
    
    if ! systemctl is-active --quiet docker; then
        error "Docker service is not running"
        return 1
    fi
    
    info "✓ Docker service is running"
    return 0
}

# Check container status
check_container_status() {
    log "Checking peer container status..."
    
    cd "$NETWORK_DIR"
    
    # Get container status
    local containers=$(docker-compose ps --services)
    local running_count=0
    local total_count=0
    
    for service in $containers; do
        total_count=$((total_count + 1))
        local status=$(docker-compose ps -q "$service" | xargs docker inspect --format='{{.State.Status}}' 2>/dev/null || echo "not_found")
        
        if [ "$status" = "running" ]; then
            info "✓ $service: Running"
            running_count=$((running_count + 1))
        elif [ "$status" = "exited" ]; then
            error "✗ $service: Exited"
        elif [ "$status" = "not_found" ]; then
            error "✗ $service: Container not found"
        else
            warn "? $service: $status"
        fi
    done
    
    info "Container Status: $running_count/$total_count running"
    
    if [ $running_count -eq $total_count ]; then
        return 0
    else
        return 1
    fi
}

# Check peer connectivity
check_peer_connectivity() {
    log "Checking peer connectivity..."
    
    # Get peer container names
    local peer_containers=$(docker ps --filter "name=peer" --format "{{.Names}}" 2>/dev/null)
    
    if [ -z "$peer_containers" ]; then
        warn "No peer containers found"
        return 1
    fi
    
    for container in $peer_containers; do
        info "Checking connectivity for $container..."
        
        # Check if peer is responsive
        local health_status=$(docker exec "$container" sh -c 'curl -s -f http://localhost:7051/healthz || echo "failed"' 2>/dev/null)
        
        if [ "$health_status" != "failed" ]; then
            info "✓ $container: Healthy"
        else
            error "✗ $container: Health check failed"
        fi
    done
}

# Check resource usage
check_resource_usage() {
    log "Checking resource usage..."
    
    # Check disk usage
    local disk_usage=$(df -h "$NETWORK_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    info "Disk usage for network directory: $disk_usage%"
    
    if [ "$disk_usage" -gt 80 ]; then
        warn "High disk usage: $disk_usage%"
    fi
    
    # Check Docker system usage
    info "Docker system information:"
    docker system df --format "table {{.Type}}\t{{.TotalCount}}\t{{.Size}}\t{{.Reclaimable}}"
}

# Check network ports
check_network_ports() {
    log "Checking network port availability..."
    
    local common_ports=(7051 7052 7053 7054 8051 8052 8053 8054 9051 9052 9053 9054)
    
    for port in "${common_ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            info "✓ Port $port: In use"
        else
            warn "Port $port: Available (may indicate service not running)"
        fi
    done
}

# Generate health report
generate_health_report() {
    log "Generating comprehensive health report..."
    
    mkdir -p "$LOG_DIR"
    local report_file="$LOG_DIR/health-report-$(date +'%Y%m%d_%H%M%S').txt"
    
    {
        echo "Hyperledger Fabric Peer Health Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo
        
        echo "Docker Status:"
        systemctl status docker --no-pager || echo "Failed to get Docker status"
        echo
        
        echo "Container Status:"
        cd "$NETWORK_DIR" && docker-compose ps || echo "Failed to get container status"
        echo
        
        echo "Resource Usage:"
        docker system df || echo "Failed to get Docker system info"
        echo
        
        echo "Network Ports:"
        netstat -tuln | grep -E ":(7051|7052|7053|7054|8051|8052|8053|8054|9051|9052|9053|9054)" || echo "No fabric ports found"
        echo
        
        echo "Recent Container Logs:"
        docker-compose logs --tail=50 || echo "Failed to get container logs"
        
    } > "$report_file"
    
    log "Health report saved to: $report_file"
}

# Display usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND] [OPTIONS]

Commands:
    status          Check overall system status (default)
    containers      Check container status only
    connectivity    Check peer connectivity only
    resources       Check resource usage only
    ports          Check network ports only
    report         Generate comprehensive health report
    help           Show this help message

Examples:
    $0              Run basic health checks
    $0 status       Same as above
    $0 containers   Check only container status
    $0 report       Generate detailed health report

EOF
}

# Main execution
main() {
    local command="${1:-status}"
    local exit_code=0
    
    case "$command" in
        "status"|"")
            log "Running Hyperledger Fabric peer health checks"
            check_docker_status || exit_code=1
            check_container_status || exit_code=1
            check_resource_usage
            info "Health check completed"
            ;;
        "containers")
            check_container_status || exit_code=1
            ;;
        "connectivity")
            check_peer_connectivity || exit_code=1
            ;;
        "resources")
            check_resource_usage
            ;;
        "ports")
            check_network_ports
            ;;
        "report")
            generate_health_report
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            error "Unknown command: $command. Use '$0 help' for usage information."
            exit_code=1
            ;;
    esac
    
    exit $exit_code
}

# Script entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
