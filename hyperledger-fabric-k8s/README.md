# Hyperledger Fabric Network on Kubernetes
<img width="1291" height="812" alt="Treetracker HLF Network" src="https://github.com/user-attachments/assets/0d799dd3-5c09-402b-8f33-ed6c2b61df25" />

A comprehensive Kubernetes deployment for a Hyperledger Fabric network designed for tree verification and environmental token management.

## 🏛️ Network Architecture

### Organizations
- **🌐 Greenstand Org**: Network admin, chaincode deployment, system governance (3 peer nodes)
- **🏢 CBO Org**: Community-based organizations, local implementation partners (2 peer nodes)
- **💰 Investor Org**: Environmental donors, impact investors, token purchasers (2 peer nodes)
- **🔍 Verifier Org**: Third-party verification services, audit organizations (1 peer node)

### Core Components
- **🏛️ Ordering Service**: 5-node Raft consensus cluster for high availability
- **🔗 Peer Nodes**: 8 total peers across 4 organizations with CouchDB state database
- **📋 Channels**: Public channel for transparency, private channels for sensitive data
- **🔐 Certificate Authority**: Root CA + Intermediate CAs for each organization
- **⛓️ Chaincode**: Tree Token contract for managing tree verification and token issuance

### Monitoring & Management
- **📊 Hyperledger Explorer**: Blockchain network explorer and transaction viewer
- **📈 Prometheus**: Metrics collection from all Fabric components
- **📉 Grafana**: Visual dashboards for network monitoring and analytics

## 📁 Project Structure

```
hyperledger-fabric-k8s/
├── base/                     # Base Kubernetes resources
│   ├── namespace.yaml        # Namespace and RBAC configuration
│   └── storage.yaml          # Storage classes and persistent volumes
├── ca/                       # Certificate Authority deployments
│   ├── root-ca.yaml          # Root Certificate Authority
│   ├── greenstand-ca.yaml    # Greenstand organization CA
│   ├── cbo-ca.yaml           # CBO organization CA
│   ├── investor-ca.yaml      # Investor organization CA
│   └── verifier-ca.yaml      # Verifier organization CA
├── orderer/                  # Ordering service configuration
│   └── raft-orderer.yaml     # 5-node Raft consensus cluster
├── peers/                    # Peer node deployments
│   ├── peer0-greenstand.yaml # Greenstand peer nodes
│   ├── peer1-greenstand.yaml
│   ├── peer2-greenstand.yaml
│   ├── peer0-cbo.yaml        # CBO peer nodes
│   ├── peer1-cbo.yaml
│   ├── peer0-investor.yaml   # Investor peer nodes
│   ├── peer1-investor.yaml
│   └── peer0-verifier.yaml   # Verifier peer node
├── channels/                 # Channel configurations
│   ├── public-channel-config.yaml    # Public channel for tree data
│   └── private-channels-config.yaml  # Private channels and collections
├── chaincode/               # Smart contract deployments
│   └── tree-token-chaincode.yaml    # Tree token management contract
├── monitoring/              # Monitoring and management tools
│   └── fabric-explorer.yaml # Explorer, Prometheus, and Grafana
└── scripts/                # Deployment and utility scripts
    ├── deploy-network.sh    # Main deployment script
    ├── generate-org-cas.sh  # CA generation script
    └── generate-peer-deployments.sh # Peer generation script
```

## 🚀 Quick Start

### Prerequisites
- Kubernetes cluster (v1.20+)
- kubectl configured to access your cluster
- At least 16GB RAM and 8 CPU cores available in cluster
- Storage provisioner configured (for persistent volumes)

### Deployment

1. **Clone and navigate to the project:**
```bash
cd hyperledger-fabric-k8s
```

2. **Make scripts executable:**
```bash
chmod +x scripts/*.sh
```

3. **Deploy the complete network:**
```bash
./scripts/deploy-network.sh
```

4. **Check deployment status:**
```bash
./scripts/deploy-network.sh --status
```

### Step-by-Step Deployment

If you prefer to deploy components individually:

```bash
# Deploy base configuration
./scripts/deploy-network.sh --base-only

# Deploy Certificate Authorities
./scripts/deploy-network.sh --cas-only

# Deploy Ordering Service
./scripts/deploy-network.sh --orderers-only

# Deploy Peer Nodes
./scripts/deploy-network.sh --peers-only

# Create Channels
./scripts/deploy-network.sh --channels-only

# Deploy Chaincode
./scripts/deploy-network.sh --chaincode-only

# Deploy Monitoring
./scripts/deploy-network.sh --monitoring-only
```

## 📊 Accessing the Network

### Web Interfaces

Once deployed, access these services through LoadBalancer IPs or port-forwarding:

- **Hyperledger Explorer**: Port 8080
  - View blockchain transactions, blocks, and network statistics
- **Grafana Dashboard**: Port 3000
  - Username: `admin`, Password: `admin`
  - Monitor network performance and health metrics
- **Prometheus**: Port 9090
  - Raw metrics and monitoring data

### Port Forwarding (for local access)
```bash
# Hyperledger Explorer
kubectl port-forward svc/hyperledger-explorer-service 8080:8080 -n hyperledger-fabric

# Grafana
kubectl port-forward svc/grafana-service 3000:3000 -n hyperledger-fabric

# Prometheus
kubectl port-forward svc/prometheus-service 9090:9090 -n hyperledger-fabric
```

## ⛓️ Chaincode Operations

The network includes a Tree Token chaincode with the following functions:

### Tree Management
- `RegisterTree`: Register a new tree with location and planting details
- `SubmitVerification`: Submit tree for third-party verification
- `CompleteVerification`: Complete verification and update tree status

### Token Operations
- `IssueTokens`: Issue environmental impact tokens based on verified trees
- `TransferToken`: Transfer token ownership
- `GetTree`: Query tree information
- `GetToken`: Query token details

### Example Usage
```bash
# Get a shell in the fabric-tools container
kubectl exec -it <fabric-tools-pod> -n hyperledger-fabric -- bash

# Register a new tree
peer chaincode invoke -o orderer-raft-service:7050 \
  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/fabric.local/orderers/orderer.fabric.local/msp/tlscacerts/tlsca.fabric.local-cert.pem \
  -C public-channel -n tree-token \
  -c '{"function":"RegisterTree","Args":["TREE001","GreenstandMSP","-1.2921","36.8219","Kenya","Nairobi","Acacia"]}'

# Query tree information
peer chaincode query -C public-channel -n tree-token \
  -c '{"function":"GetTree","Args":["TREE001"]}'
```

## 🔧 Configuration

### Resource Requirements

| Component | Replicas | CPU Request | Memory Request | Storage |
|-----------|----------|-------------|----------------|---------|
| CA (each) | 1 | 100m | 256Mi | 2Gi |
| Orderer | 5 | 500m | 1Gi | 10Gi |
| Peer (each) | 1 | 500m | 1Gi | 15Gi |
| CouchDB (each) | 1 | 250m | 512Mi | 5Gi |
| Explorer | 1 | 250m | 512Mi | - |
| Prometheus | 1 | 100m | 256Mi | 10Gi |
| Grafana | 1 | 100m | 256Mi | 5Gi |

### Scaling

To scale peer nodes, modify the peer deployment files and update channel configurations accordingly.

### TLS and Security

All components are configured with TLS enabled:
- Peer-to-peer communication encrypted
- Client-to-peer communication encrypted
- Orderer communication encrypted
- Certificate-based authentication

## 📋 Channel Configuration

### Public Channel
- **Name**: `public-channel`
- **Participants**: All organizations
- **Purpose**: Tree verification data and public token transactions
- **Endorsement Policy**: Majority endorsement required

### Private Channels
- **Greenstand-CBO Private**: Sensitive collaboration data
- **Investor-Verifier Private**: Financial and audit data
- **Cross-Org Collections**: Multi-party private data sharing

## 🔍 Monitoring and Logging

### Prometheus Metrics
The setup collects metrics from:
- Peer nodes (endorsement metrics, ledger metrics)
- Orderer nodes (consensus metrics, transaction metrics)
- Certificate Authorities (enrollment metrics)

### Grafana Dashboards
Pre-configured dashboards for:
- Network overview and health
- Transaction throughput and latency
- Resource utilization
- Certificate and identity management

### Logs Access
```bash
# View peer logs
kubectl logs <peer-pod-name> -n hyperledger-fabric

# View orderer logs
kubectl logs <orderer-pod-name> -n hyperledger-fabric

# View CA logs
kubectl logs <ca-pod-name> -n hyperledger-fabric
```

## 🛠️ Troubleshooting

### Common Issues

1. **Pods in Pending State**
   - Check storage provisioner configuration
   - Verify node resources availability

2. **Certificate Issues**
   - Ensure CA pods are running before deploying peers
   - Check certificate expiration dates

3. **Channel Creation Fails**
   - Verify orderer service is ready
   - Check network policies and connectivity

4. **Chaincode Installation Issues**
   - Ensure all peers are joined to the channel
   - Verify chaincode package format

### Debug Commands
```bash
# Check pod status and events
kubectl describe pod <pod-name> -n hyperledger-fabric

# View persistent volume claims
kubectl get pvc -n hyperledger-fabric

# Check service connectivity
kubectl exec -it <pod-name> -n hyperledger-fabric -- nslookup <service-name>

# View fabric network logs
kubectl logs -f <pod-name> -n hyperledger-fabric
```

## 🚫 Cleanup

To remove the entire network:

```bash
# Delete all resources in the namespace
kubectl delete namespace hyperledger-fabric

# Remove persistent volumes (if needed)
kubectl delete pv fabric-ca-pv fabric-orderer-pv fabric-peer-pv
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## 🆘 Support

For issues and questions:
1. Check the troubleshooting section above
2. Review Hyperledger Fabric documentation
3. Open an issue in the project repository
4. Join the Hyperledger Fabric community channels

---

**Note**: This setup is designed for development and testing environments. For production deployments, additional security hardening, backup strategies, and high availability configurations should be implemented.
