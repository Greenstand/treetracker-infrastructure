#!/bin/bash

set -e

echo "🚀 Deploying Hyperledger Fabric Network on Kubernetes"
echo "======================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "❌ kubectl is not installed. Please install kubectl first."
        exit 1
    fi
    echo "✅ kubectl is available"
}

# Function to check if Kubernetes cluster is accessible
check_k8s_cluster() {
    if ! kubectl cluster-info &> /dev/null; then
        echo "❌ Cannot connect to Kubernetes cluster. Please check your configuration."
        exit 1
    fi
    echo "✅ Kubernetes cluster is accessible"
}

# Function to create namespace and base resources
deploy_base() {
    echo "📦 Deploying base configuration..."
    kubectl apply -f "$PROJECT_DIR/base/namespace.yaml"
    kubectl apply -f "$PROJECT_DIR/base/storage.yaml"
    echo "✅ Base configuration deployed"
}

# Function to deploy Certificate Authorities
deploy_cas() {
    echo "🔐 Deploying Certificate Authorities..."
    kubectl apply -f "$PROJECT_DIR/ca/root-ca.yaml"
    kubectl apply -f "$PROJECT_DIR/ca/greenstand-ca.yaml"
    kubectl apply -f "$PROJECT_DIR/ca/cbo-ca.yaml"
    kubectl apply -f "$PROJECT_DIR/ca/investor-ca.yaml"
    kubectl apply -f "$PROJECT_DIR/ca/verifier-ca.yaml"
    
    echo "⏳ Waiting for CAs to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/fabric-ca-root -n hyperledger-fabric
    kubectl wait --for=condition=available --timeout=300s deployment/fabric-ca-greenstand -n hyperledger-fabric
    kubectl wait --for=condition=available --timeout=300s deployment/fabric-ca-cbo -n hyperledger-fabric
    kubectl wait --for=condition=available --timeout=300s deployment/fabric-ca-investor -n hyperledger-fabric
    kubectl wait --for=condition=available --timeout=300s deployment/fabric-ca-verifier -n hyperledger-fabric
    echo "✅ Certificate Authorities deployed and ready"
}

# Function to deploy ordering service
deploy_orderers() {
    echo "📋 Deploying Ordering Service..."
    kubectl apply -f "$PROJECT_DIR/orderer/raft-orderer.yaml"
    
    echo "⏳ Waiting for orderers to be ready..."
    kubectl wait --for=condition=ready --timeout=300s statefulset/orderer-raft -n hyperledger-fabric
    echo "✅ Ordering service deployed and ready"
}

# Function to deploy peers
deploy_peers() {
    echo "🌐 Deploying Peer nodes..."
    for peer_file in "$PROJECT_DIR/peers"/peer*.yaml; do
        echo "Deploying $(basename "$peer_file")..."
        kubectl apply -f "$peer_file"
    done
    
    echo "⏳ Waiting for peers to be ready..."
    # Wait for all peer deployments
    for org in greenstand cbo investor verifier; do
        case $org in
            greenstand) peer_count=3 ;;
            cbo) peer_count=2 ;;
            investor) peer_count=2 ;;
            verifier) peer_count=1 ;;
        esac
        
        for ((i=0; i<peer_count; i++)); do
            kubectl wait --for=condition=available --timeout=300s deployment/peer${i}-${org} -n hyperledger-fabric
        done
    done
    echo "✅ All peer nodes deployed and ready"
}

# Function to deploy channels
deploy_channels() {
    echo "📺 Creating channels..."
    kubectl apply -f "$PROJECT_DIR/channels/public-channel-config.yaml"
    kubectl apply -f "$PROJECT_DIR/channels/private-channels-config.yaml"
    
    echo "⏳ Waiting for channel creation jobs to complete..."
    kubectl wait --for=condition=complete --timeout=300s job/create-public-channel -n hyperledger-fabric
    kubectl wait --for=condition=complete --timeout=300s job/setup-private-channels -n hyperledger-fabric
    echo "✅ Channels created successfully"
}

# Function to deploy chaincode
deploy_chaincode() {
    echo "⛓️ Deploying chaincode..."
    kubectl apply -f "$PROJECT_DIR/chaincode/tree-token-chaincode.yaml"
    
    echo "⏳ Waiting for chaincode installation to complete..."
    kubectl wait --for=condition=complete --timeout=600s job/install-tree-token-chaincode -n hyperledger-fabric
    echo "✅ Chaincode deployed successfully"
}

# Function to deploy monitoring
deploy_monitoring() {
    echo "📊 Deploying monitoring stack..."
    kubectl apply -f "$PROJECT_DIR/monitoring/fabric-explorer.yaml"
    
    echo "⏳ Waiting for monitoring components to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/hyperledger-explorer -n hyperledger-fabric
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n hyperledger-fabric
    kubectl wait --for=condition=available --timeout=300s deployment/grafana -n hyperledger-fabric
    echo "✅ Monitoring stack deployed and ready"
}

# Function to display network status
show_network_status() {
    echo ""
    echo "🎉 Hyperledger Fabric Network Deployment Complete!"
    echo "=================================================="
    echo ""
    echo "📊 Network Components Status:"
    echo "------------------------------"
    kubectl get pods -n hyperledger-fabric -o wide
    echo ""
    echo "🌐 Network Services:"
    echo "--------------------"
    kubectl get services -n hyperledger-fabric
    echo ""
    echo "📱 Access URLs (if using LoadBalancer):"
    echo "---------------------------------------"
    echo "• Hyperledger Explorer: http://$(kubectl get service hyperledger-explorer-service -n hyperledger-fabric -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):8080"
    echo "• Prometheus: http://$(kubectl get service prometheus-service -n hyperledger-fabric -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):9090"
    echo "• Grafana: http://$(kubectl get service grafana-service -n hyperledger-fabric -o jsonpath='{.status.loadBalancer.ingress[0].ip}'):3000"
    echo "  - Default credentials: admin/admin"
    echo ""
    echo "🏢 Organizations and Peers:"
    echo "---------------------------"
    echo "• Greenstand: 3 peers (network admin, chaincode deployment, system governance)"
    echo "• CBO: 2 peers (community-based organizations, local implementation)"
    echo "• Investor: 2 peers (environmental donors, impact investors, token purchasers)"
    echo "• Verifier: 1 peer (third-party verification services, audit organizations)"
    echo ""
    echo "📋 Ordering Service:"
    echo "--------------------"
    echo "• 5-node Raft consensus cluster for high availability"
    echo ""
    echo "📺 Channels:"
    echo "------------"
    echo "• Public Channel: Tree verification and token data"
    echo "• Private Channels: Sensitive organizational data"
    echo "• Cross-Channel: Multi-organization transactions"
    echo ""
    echo "⛓️ Chaincode:"
    echo "-------------"
    echo "• Tree Token Contract: Manages tree registration, verification, and token issuance"
    echo ""
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Deploy Hyperledger Fabric network on Kubernetes"
    echo ""
    echo "Options:"
    echo "  --help, -h          Show this help message"
    echo "  --base-only         Deploy only base configuration"
    echo "  --cas-only          Deploy only Certificate Authorities"
    echo "  --orderers-only     Deploy only ordering service"
    echo "  --peers-only        Deploy only peer nodes"
    echo "  --channels-only     Deploy only channels"
    echo "  --chaincode-only    Deploy only chaincode"
    echo "  --monitoring-only   Deploy only monitoring stack"
    echo "  --status            Show network status"
    echo ""
    echo "Examples:"
    echo "  $0                  # Full deployment"
    echo "  $0 --base-only      # Deploy base configuration only"
    echo "  $0 --status         # Show current network status"
}

# Main deployment logic
main() {
    case "${1:-full}" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --base-only)
            check_kubectl
            check_k8s_cluster
            deploy_base
            ;;
        --cas-only)
            check_kubectl
            check_k8s_cluster
            deploy_cas
            ;;
        --orderers-only)
            check_kubectl
            check_k8s_cluster
            deploy_orderers
            ;;
        --peers-only)
            check_kubectl
            check_k8s_cluster
            deploy_peers
            ;;
        --channels-only)
            check_kubectl
            check_k8s_cluster
            deploy_channels
            ;;
        --chaincode-only)
            check_kubectl
            check_k8s_cluster
            deploy_chaincode
            ;;
        --monitoring-only)
            check_kubectl
            check_k8s_cluster
            deploy_monitoring
            ;;
        --status)
            show_network_status
            ;;
        full)
            echo "🚀 Starting full Hyperledger Fabric network deployment..."
            check_kubectl
            check_k8s_cluster
            deploy_base
            sleep 10
            deploy_cas
            sleep 10
            deploy_orderers
            sleep 15
            deploy_peers
            sleep 15
            deploy_channels
            sleep 10
            deploy_chaincode
            sleep 10
            deploy_monitoring
            show_network_status
            ;;
        *)
            echo "❌ Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
