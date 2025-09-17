#!/bin/bash
# Orderer Infrastructure Check Script
# Usage: ./scripts/check.sh [summary|deep|secrets-only|consensus-only]

set -e

# Default configuration
NAMESPACE="orderer"
CHART_LABEL="app.kubernetes.io/part-of=hyperledger-fabric"
ORDERER_LABEL="app.kubernetes.io/name=fabric-orderer"

# Color output functions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Usage function
usage() {
    cat << EOF
Orderer Infrastructure Check Script

Usage: $0 [MODE]

MODE:
  summary        Basic check of pods, services, PVCs, consensus leader (default)
  deep           Full check including certificates, secrets, consensus health, Genesis block
  secrets-only   Check only MSP/TLS secrets structure and cert/key matching
  consensus-only Check only Raft consensus health and leadership

Examples:
  $0                    # Run summary check
  $0 deep              # Run comprehensive check
  $0 secrets-only      # Check only certificates and secrets
  $0 consensus-only    # Check only consensus health

EOF
}

# Check if kubectl is available
check_prerequisites() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    if ! command -v openssl &> /dev/null; then
        log_warning "openssl not found. Certificate validation will be skipped."
        OPENSSL_AVAILABLE=false
    else
        OPENSSL_AVAILABLE=true
    fi
    
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        log_error "Namespace $NAMESPACE does not exist"
        exit 1
    fi
}

# Check orderer pods status
check_pods() {
    log_info "Checking orderer pods in namespace $NAMESPACE..."
    
    local pods
    pods=$(kubectl -n "$NAMESPACE" get pods --selector="$ORDERER_LABEL" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -z "$pods" ]]; then
        log_error "No orderer pods found in namespace $NAMESPACE"
        return 1
    fi
    
    local total_pods=0
    local running_pods=0
    local error_pods=0
    
    for pod in $pods; do
        ((total_pods++))
        local phase
        phase=$(kubectl -n "$NAMESPACE" get pod "$pod" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        
        local ready
        ready=$(kubectl -n "$NAMESPACE" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
        
        if [[ "$phase" == "Running" && "$ready" == "true" ]]; then
            ((running_pods++))
            log_success "Pod $pod is Running and Ready"
        else
            ((error_pods++))
            log_error "Pod $pod is $phase (ready: $ready)"
            
            # Show recent events for failed pods
            log_info "Recent events for $pod:"
            kubectl -n "$NAMESPACE" get events --field-selector involvedObject.name="$pod" --sort-by='.lastTimestamp' | tail -3 || true
        fi
    done
    
    log_info "Pod Summary: $running_pods/$total_pods running, $error_pods errors"
    
    if [[ $error_pods -gt 0 ]]; then
        return 1
    fi
}

# Check services and storage
check_services_and_storage() {
    log_info "Checking orderer services and storage..."
    
    # Check services
    local services
    services=$(kubectl -n "$NAMESPACE" get svc --selector="$ORDERER_LABEL" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -n "$services" ]]; then
        for svc in $services; do
            local endpoints
            endpoints=$(kubectl -n "$NAMESPACE" get endpoints "$svc" -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null || echo "")
            
            if [[ -n "$endpoints" ]]; then
                log_success "Service $svc has endpoints: $endpoints"
            else
                log_warning "Service $svc has no endpoints"
            fi
        done
    else
        log_warning "No orderer services found"
    fi
    
    # Check PVCs
    local pvcs
    pvcs=$(kubectl -n "$NAMESPACE" get pvc -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -n "$pvcs" ]]; then
        for pvc in $pvcs; do
            local status
            status=$(kubectl -n "$NAMESPACE" get pvc "$pvc" -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
            
            if [[ "$status" == "Bound" ]]; then
                log_success "PVC $pvc is Bound"
            else
                log_error "PVC $pvc is $status"
            fi
        done
    else
        log_warning "No PVCs found for orderer"
    fi
}

# Check Raft consensus health
check_consensus() {
    log_info "Checking Raft consensus health..."
    
    local pods
    pods=$(kubectl -n "$NAMESPACE" get pods --selector="$ORDERER_LABEL" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    if [[ -z "$pods" ]]; then
        log_error "No orderer pods found for consensus check"
        return 1
    fi
    
    local leader_found=false
    local cluster_size=0
    
    for pod in $pods; do
        ((cluster_size++))
        
        # Check if pod is ready
        local ready
        ready=$(kubectl -n "$NAMESPACE" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
        
        if [[ "$ready" != "true" ]]; then
            log_warning "Pod $pod is not ready, skipping consensus check"
            continue
        fi
        
        # Check for leadership in logs
        local recent_logs
        recent_logs=$(kubectl -n "$NAMESPACE" logs "$pod" --tail=100 2>/dev/null | grep -i "raft" | tail -10 || echo "")
        
        if echo "$recent_logs" | grep -q "became leader\|is leader"; then
            log_success "Pod $pod is Raft leader"
            leader_found=true
        elif echo "$recent_logs" | grep -q "lost leadership"; then
            log_warning "Pod $pod recently lost leadership"
        fi
        
        # Check for recent Raft activity
        if echo "$recent_logs" | grep -q -E "heartbeat|election|replication"; then
            log_success "Pod $pod shows recent Raft activity"
        else
            log_warning "Pod $pod shows no recent Raft activity"
        fi
    done
    
    # Consensus health summary
    log_info "Consensus Summary: $cluster_size orderers, leader found: $leader_found"
    
    if [[ "$leader_found" == "false" ]]; then
        log_error "No Raft leader found - consensus may be unhealthy"
        return 1
    fi
    
    # Check quorum requirements
    local min_nodes=3
    if [[ $cluster_size -lt $min_nodes ]]; then
        log_warning "Cluster size ($cluster_size) is below recommended minimum ($min_nodes)"
    fi
    
    if [[ $((cluster_size % 2)) -eq 0 ]]; then
        log_warning "Even number of orderers ($cluster_size) - odd numbers recommended for Raft"
    fi
}

# Check Genesis block
check_genesis_block() {
    log_info "Checking Genesis block..."
    
    # Check ConfigMap
    local genesis_cm="fabric-genesis-block"
    if kubectl -n "$NAMESPACE" get configmap "$genesis_cm" &>/dev/null; then
        log_success "Genesis block ConfigMap $genesis_cm exists"
        
        # Check if genesis.block key exists
        if kubectl -n "$NAMESPACE" get configmap "$genesis_cm" -o jsonpath='{.data.genesis\.block}' &>/dev/null; then
            log_success "Genesis block data found in ConfigMap"
        else
            log_error "Genesis block data missing from ConfigMap"
            return 1
        fi
    else
        log_error "Genesis block ConfigMap $genesis_cm not found"
        return 1
    fi
    
    # Check if Genesis block is accessible in pods
    local pods
    pods=$(kubectl -n "$NAMESPACE" get pods --selector="$ORDERER_LABEL" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")
    
    for pod in $pods; do
        local ready
        ready=$(kubectl -n "$NAMESPACE" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
        
        if [[ "$ready" == "true" ]]; then
            if kubectl -n "$NAMESPACE" exec "$pod" -- test -f /var/hyperledger/orderer/genesis.block 2>/dev/null; then
                log_success "Genesis block accessible in pod $pod"
            else
                log_error "Genesis block not accessible in pod $pod"
                return 1
            fi
            break # Only need to check one running pod
        fi
    done
}

# Check MSP and TLS secrets
check_secrets() {
    log_info "Checking orderer MSP and TLS secrets..."
    
    # Find orderer secrets
    local msp_secret="fabric-orderer-msp"
    local tls_secret="fabric-orderer-tls"
    
    # Check MSP secret
    if kubectl -n "$NAMESPACE" get secret "$msp_secret" &>/dev/null; then
        check_msp_secret "$msp_secret"
    else
        log_error "MSP secret $msp_secret not found"
        return 1
    fi
    
    # Check TLS secret
    if kubectl -n "$NAMESPACE" get secret "$tls_secret" &>/dev/null; then
        check_tls_secret "$tls_secret"
    else
        log_error "TLS secret $tls_secret not found"
        return 1
    fi
}

# Check MSP secret structure
check_msp_secret() {
    local secret="$1"
    
    log_info "Validating MSP secret $secret"
    
    local required_keys=("cacerts" "signcerts" "keystore" "config.yaml")
    local missing_keys=()
    
    for key in "${required_keys[@]}"; do
        if ! kubectl -n "$NAMESPACE" get secret "$secret" -o jsonpath="{.data.$key}" &>/dev/null; then
            missing_keys+=("$key")
        fi
    done
    
    if [[ ${#missing_keys[@]} -eq 0 ]]; then
        log_success "MSP secret $secret has all required keys"
        
        # Check if config.yaml contains NodeOUs
        local config_yaml
        config_yaml=$(kubectl -n "$NAMESPACE" get secret "$secret" -o jsonpath='{.data.config\.yaml}' | base64 -d 2>/dev/null || echo "")
        
        if [[ -n "$config_yaml" ]]; then
            if echo "$config_yaml" | grep -q "NodeOUs"; then
                log_success "MSP config.yaml contains NodeOUs configuration"
            else
                log_warning "MSP config.yaml does not contain NodeOUs configuration"
            fi
            
            if echo "$config_yaml" | grep -q "OrdererOUIdentifier"; then
                log_success "MSP config.yaml contains OrdererOUIdentifier"
            else
                log_warning "MSP config.yaml missing OrdererOUIdentifier"
            fi
        fi
    else
        log_error "MSP secret $secret missing keys: ${missing_keys[*]}"
        return 1
    fi
}

# Check TLS secret structure
check_tls_secret() {
    local secret="$1"
    
    log_info "Validating TLS secret $secret"
    
    local required_keys=("tls.crt" "tls.key" "ca.crt")
    local missing_keys=()
    
    for key in "${required_keys[@]}"; do
        if ! kubectl -n "$NAMESPACE" get secret "$secret" -o jsonpath="{.data.$key}" &>/dev/null; then
            missing_keys+=("$key")
        fi
    done
    
    if [[ ${#missing_keys[@]} -eq 0 ]]; then
        log_success "TLS secret $secret has all required keys"
        
        # Validate certificate/key matching if openssl is available
        if [[ "$OPENSSL_AVAILABLE" == "true" ]]; then
            check_tls_cert_key_match "$secret"
        fi
    else
        log_error "TLS secret $secret missing keys: ${missing_keys[*]}"
        return 1
    fi
}

# Check if TLS certificate and key match
check_tls_cert_key_match() {
    local secret="$1"
    
    log_info "Checking TLS cert/key pair for $secret"
    
    # Extract cert and key to temp files
    local cert_file="/tmp/${secret}-cert.pem"
    local key_file="/tmp/${secret}-key.pem"
    
    kubectl -n "$NAMESPACE" get secret "$secret" -o jsonpath='{.data.tls\.crt}' | base64 -d > "$cert_file" 2>/dev/null || {
        log_error "Failed to extract certificate from $secret"
        return 1
    }
    
    kubectl -n "$NAMESPACE" get secret "$secret" -o jsonpath='{.data.tls\.key}' | base64 -d > "$key_file" 2>/dev/null || {
        log_error "Failed to extract private key from $secret"
        rm -f "$cert_file"
        return 1
    }
    
    # Compare modulus
    local cert_modulus key_modulus
    cert_modulus=$(openssl x509 -noout -modulus -in "$cert_file" 2>/dev/null | openssl md5 2>/dev/null || echo "")
    key_modulus=$(openssl rsa -noout -modulus -in "$key_file" 2>/dev/null | openssl md5 2>/dev/null || echo "")
    
    # Check certificate SANs for orderer service names
    local sans
    sans=$(openssl x509 -noout -text -in "$cert_file" 2>/dev/null | grep -A1 "Subject Alternative Name" | grep -o "DNS:[^,]*" | head -5 || echo "")
    
    # Clean up temp files
    rm -f "$cert_file" "$key_file"
    
    if [[ -n "$cert_modulus" && -n "$key_modulus" && "$cert_modulus" == "$key_modulus" ]]; then
        log_success "TLS cert/key pair matches for $secret"
    else
        log_error "TLS cert/key pair MISMATCH for $secret"
        log_error "  Certificate modulus: $cert_modulus"
        log_error "  Private key modulus: $key_modulus"
        return 1
    fi
    
    if [[ -n "$sans" ]]; then
        log_success "Certificate SANs found: $(echo "$sans" | tr '\n' ' ')"
        
        # Check if orderer service names are in SANs
        if echo "$sans" | grep -q "fabric-orderer"; then
            log_success "Orderer service name found in certificate SANs"
        else
            log_warning "Orderer service name may be missing from certificate SANs"
        fi
    else
        log_warning "No Subject Alternative Names found in certificate"
    fi
}

# Check certificate expiration
check_cert_expiration() {
    log_info "Checking certificate expiration..."
    
    local tls_secret="fabric-orderer-tls"
    
    if [[ "$OPENSSL_AVAILABLE" == "true" ]] && kubectl -n "$NAMESPACE" get secret "$tls_secret" &>/dev/null; then
        local cert_file="/tmp/${tls_secret}-cert.pem"
        kubectl -n "$NAMESPACE" get secret "$tls_secret" -o jsonpath='{.data.tls\.crt}' | base64 -d > "$cert_file" 2>/dev/null || return 1
        
        local expiry_date
        expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2 || echo "")
        
        if [[ -n "$expiry_date" ]]; then
            local expiry_epoch current_epoch days_remaining
            expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo "0")
            current_epoch=$(date +%s)
            days_remaining=$(( (expiry_epoch - current_epoch) / 86400 ))
            
            if [[ $days_remaining -lt 30 ]]; then
                log_error "Certificate expires in $days_remaining days ($expiry_date)"
            elif [[ $days_remaining -lt 90 ]]; then
                log_warning "Certificate expires in $days_remaining days ($expiry_date)"
            else
                log_success "Certificate expires in $days_remaining days"
            fi
        fi
        
        rm -f "$cert_file"
    fi
}

# Check orderer connectivity from peers
check_peer_connectivity() {
    log_info "Checking peer connectivity to orderer..."
    
    local orderer_service="fabric-orderer"
    local orderer_port="7050"
    
    # Check if orderer service is accessible
    if kubectl -n "$NAMESPACE" get svc "$orderer_service" &>/dev/null; then
        local cluster_ip
        cluster_ip=$(kubectl -n "$NAMESPACE" get svc "$orderer_service" -o jsonpath='{.spec.clusterIP}')
        
        if [[ -n "$cluster_ip" && "$cluster_ip" != "None" ]]; then
            log_success "Orderer service $orderer_service has ClusterIP: $cluster_ip"
        else
            log_warning "Orderer service $orderer_service has no ClusterIP"
        fi
    else
        log_error "Orderer service $orderer_service not found"
        return 1
    fi
}

# Main function
main() {
    local mode="${1:-summary}"
    
    case "$mode" in
        "help"|"-h"|"--help")
            usage
            exit 0
            ;;
        "summary")
            log_info "Running summary check..."
            check_prerequisites
            check_pods && check_services_and_storage && check_consensus
            ;;
        "deep")
            log_info "Running comprehensive check..."
            check_prerequisites
            check_pods
            check_services_and_storage
            check_consensus
            check_genesis_block
            check_secrets
            check_cert_expiration
            check_peer_connectivity
            ;;
        "secrets-only")
            log_info "Running secrets-only check..."
            check_prerequisites
            check_secrets
            check_cert_expiration
            ;;
        "consensus-only")
            log_info "Running consensus-only check..."
            check_prerequisites
            check_consensus
            ;;
        *)
            log_error "Unknown mode: $mode"
            usage
            exit 1
            ;;
    esac
    
    log_info "Check completed."
}

# Execute main function with all arguments
main "$@"
