# Hyperledger Fabric Orderer Infrastructure

Production-ready Hyperledger Fabric orderer infrastructure for Kubernetes, featuring Raft consensus, comprehensive documentation, security policies, and operational tooling.

## 🚀 Quick Start

```bash
# Health check
./scripts/check.sh

# Deploy orderer cluster
helm upgrade --install fabric-orderer "./helm/orderer" -n orderer -f values-orderer.yaml --create-namespace

# Verify deployment
kubectl -n orderer get pods,svc,pvc

# Check consensus health
./scripts/check.sh consensus-only
```

## 📁 Repository Structure

```
orderer/
├── DOCUMENTATION_INDEX.md          # 📋 Master documentation index
├── TECHNICAL_SPECS.md              # 🏗️  Architecture & technical design
├── OPERATIONAL_PROCEDURES.md       # 🔧 Day-2 operations & runbooks
├── SECURITY_PROCEDURES.md          # 🛡️  Security controls & hardening
├── scripts/
│   └── check.sh                    # ✅ One-click health validation
├── policies/kyverno/               # 🔐 Security admission policies
│   ├── disallow-latest-tags.yaml
│   ├── enforce-security-context.yaml
│   ├── validate-orderer-secrets.yaml
│   ├── validate-genesis-block.yaml
│   ├── restrict-network-access.yaml
│   └── README.md
└── [Helm charts, values, secrets]  # 📦 Deployment artifacts
```

## 🏛️ Consensus Architecture

| Component | Purpose | Configuration | Status |
|-----------|---------|---------------|--------|
| **Raft Cluster** | Consensus mechanism | 3-7 orderers (odd numbers) | ✅ Active |
| **Genesis Block** | Network bootstrap | ConfigMap-based | ✅ Available |
| **Leader Election** | Consensus leadership | Automatic failover | ✅ Monitored |
| **Log Replication** | Transaction ordering | Distributed ledger | ✅ Replicated |

## 🎯 Key Features

### 📚 **Comprehensive Documentation**
- **Technical Specifications**: Complete architecture reference
- **Operational Procedures**: Production-ready runbooks
- **Security Procedures**: Consensus security and hardening guidance
- **Documentation Index**: Master navigation and overview

### 🔍 **One-Click Health Validation**
```bash
./scripts/check.sh [summary|deep|secrets-only|consensus-only]
```
- Raft consensus health and leadership
- Pod and service health
- Genesis block validation
- MSP/TLS secret structure validation
- Certificate/key pair verification
- Certificate expiration monitoring

### 🛡️ **Security-First Design**
- **Kyverno Policies**: Admission control for security baselines
- **Consensus Security**: Raft cluster protection and integrity
- **mTLS Everywhere**: Peer connections, inter-orderer, operations
- **Network Isolation**: NetworkPolicies and ingress restrictions
- **Genesis Block Protection**: Tamper-evident network configuration

### 🎛️ **Production Operations**
- **Raft Consensus**: 3-node fault-tolerant cluster
- **Helm-Based**: GitOps-ready deployments
- **Scalable**: Add/remove orderers safely
- **Observable**: Prometheus metrics, consensus monitoring
- **Recoverable**: Backup/restore with disaster recovery

## 📖 Documentation Quick Links

| Document | Purpose | Quick Access |
|----------|---------|--------------| 
| 📋 [Documentation Index](./DOCUMENTATION_INDEX.md) | Master overview and navigation | **Start here** |
| 🏗️ [Technical Specs](./TECHNICAL_SPECS.md) | Architecture, Kubernetes resources, Raft | Engineers |
| 🔧 [Operations](./OPERATIONAL_PROCEDURES.md) | Deploy, consensus ops, troubleshoot | Operations |
| 🛡️ [Security](./SECURITY_PROCEDURES.md) | Hardening, policies, incident response | Security |

## ⚡ Common Tasks

### Deploy Orderer Cluster
```bash
# Set chart path  
CHART_PATH="./helm/orderer"

# Deploy with orderer configuration
helm upgrade --install fabric-orderer "$CHART_PATH" \
  -n orderer -f values-orderer.yaml --create-namespace

# Verify Raft cluster formation
kubectl -n orderer logs fabric-orderer-0 | grep -i "raft\|leader"
```

### Health Check
```bash
# Quick consensus check
./scripts/check.sh

# Full validation with certificates and Genesis block
./scripts/check.sh deep

# Only validate Raft consensus health
./scripts/check.sh consensus-only
```

### Scale Orderer Cluster
```bash
# Scale to 5 nodes (must be odd number)
kubectl -n orderer scale sts fabric-orderer --replicas=5

# Verify new nodes join Raft cluster
kubectl -n orderer logs fabric-orderer-4 | grep "joined.*cluster"
```

### Troubleshoot Issues
```bash
# Check orderer pod status
kubectl -n orderer get pods -l app.kubernetes.io/name=fabric-orderer

# View consensus logs
kubectl -n orderer logs fabric-orderer-0 --tail=200

# Validate secrets and Genesis block
kubectl -n orderer describe secret fabric-orderer-msp
kubectl -n orderer describe configmap fabric-genesis-block

# Check secret structure
./scripts/check.sh secrets-only
```

## 🔐 Security Features

### Admission Policies (Kyverno)
```bash
# Install Kyverno
kubectl apply -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml

# Apply orderer security policies
kubectl apply -f policies/kyverno/

# Verify policies
kubectl get cpol
```

**Policy Coverage**:
- ✅ Block `:latest` image tags
- ✅ Enforce non-root containers
- ✅ Require seccomp profiles
- ✅ Drop all Linux capabilities
- ✅ Validate MSP/TLS secret structure
- ✅ Validate Genesis block ConfigMap
- ✅ Network ingress restrictions

### Consensus Security
```bash
# Monitor Raft leadership
kubectl -n orderer logs fabric-orderer-0 | grep "became leader\|lost leadership"

# Check cluster membership
kubectl -n orderer logs fabric-orderer-0 | grep "cluster membership"

# Validate Genesis block consistency
./scripts/check.sh deep
```

## 🏗️ Architecture Overview

### Kubernetes Resources
- **StatefulSet**: Orderer cluster with persistent identity (fabric-orderer)
- **Services**: ClusterIP (peer access) + Headless (Raft discovery)
- **PVC**: Persistent storage for Raft logs and ledger data
- **Secrets**: MSP (orderer identity) + TLS (transport security)
- **ConfigMap**: Genesis block (network bootstrap configuration)
- **NetworkPolicy**: Ingress restrictions and peer access control

### Raft Consensus
```
Orderer Cluster (3 nodes):
├── fabric-orderer-0 (Leader)    # Active leader, processes transactions
├── fabric-orderer-1 (Follower)  # Replicates leader's log
└── fabric-orderer-2 (Follower)  # Replicates leader's log

Fault Tolerance: (3-1)/2 = 1 node failure tolerated
```

### Genesis Block Structure
```
Genesis Block ConfigMap:
├── genesis.block           # Binary genesis block file
├── Consortium definitions  # Network participants
├── Orderer MSP definitions # Orderer organization identity
└── Raft configuration     # Consensus parameters
```

## 🔧 Prerequisites

### Required Tools
- `kubectl` - Kubernetes CLI
- `helm` - Kubernetes package manager
- `openssl` - Certificate validation (optional)

### Cluster Requirements
- Kubernetes 1.20+
- RBAC enabled
- StorageClass for persistent volumes (high IOPS recommended)
- Optional: Kyverno for admission policies

### Network Access
- Peer organizations (ingress on port 7050)
- Inter-orderer Raft communication (port 7050)
- Operations/metrics endpoint (port 9443, optional)

## 🚨 Emergency Procedures

### Consensus Failure (No Leader)
1. Check logs: `kubectl -n orderer logs fabric-orderer-0 | grep -i raft`
2. Validate Genesis block: `./scripts/check.sh deep`
3. See [Operations Guide](./OPERATIONAL_PROCEDURES.md#102-raft-consensus-issues)

### Certificate Issues
1. Run certificate check: `./scripts/check.sh secrets-only`
2. Follow [Security Guide](./SECURITY_PROCEDURES.md#132-tls-certificate-emergency)
3. Recreate secrets if needed

### Genesis Block Corruption
1. Validate ConfigMap: `kubectl -n orderer describe configmap fabric-genesis-block`
2. Follow [Security Guide](./SECURITY_PROCEDURES.md#133-genesis-block-corruption)
3. Restore from backup if needed

## 📊 Monitoring

### Consensus Health
```bash
# Check current leader
kubectl -n orderer logs fabric-orderer-0 | grep "became leader"

# Monitor block production
kubectl -n orderer logs fabric-orderer-0 | grep "Created block"

# Raft cluster membership
kubectl -n orderer logs fabric-orderer-0 | grep "cluster membership"
```

### Operations Endpoint
```bash
# Port-forward to operations endpoint
kubectl -n orderer port-forward svc/fabric-orderer 9443:9443

# Check health
curl -sk https://localhost:9443/healthz

# View metrics (if enabled)
curl -sk https://localhost:9443/metrics | grep consensus
```

### Log Aggregation
```bash
# Stream all orderer logs
kubectl -n orderer logs -l app.kubernetes.io/name=fabric-orderer -f

# Specific orderer logs
kubectl -n orderer logs fabric-orderer-0 -f
```

## 🤝 Contributing

### Documentation Updates
1. Fork repository and create feature branch
2. Update relevant documentation files  
3. Test changes with `./scripts/check.sh deep`
4. Submit pull request with clear description

### Scaling Orderer Cluster
1. Plan: odd numbers only (3, 5, 7)
2. Update Genesis block with new orderer definitions
3. Scale: `kubectl -n orderer scale sts fabric-orderer --replicas=5`
4. Verify: monitor logs for cluster membership changes
5. Update documentation

## 📞 Support

### Team Contacts
- **Platform/SRE Team**: Technical architecture, Kubernetes infrastructure, Raft consensus
- **Operations Team**: Deployment, scaling, day-2 operations
- **Security Team**: Policies, Genesis block, certificate management, incident response

### Escalation Guidelines
- **Consensus Failures**: Immediate SRE escalation
- **Certificate Issues**: Security team consultation
- **Genesis Block Issues**: Network-wide coordination required
- **Network Partitions**: Infrastructure team coordination

### Useful Commands Reference
```bash
# Get all orderer resources
kubectl -n orderer get all,secrets,configmaps,pvc

# Check Helm release
helm list -n orderer

# View Kyverno policies
kubectl get cpol | grep orderer

# Monitor Raft consensus
kubectl -n orderer logs -f fabric-orderer-0 | grep -i raft
```

---

**📍 Location**: `/root/hyperledger-fabric-network/orderer/`  
**🏷️ Version**: 1.0  
**📅 Last Updated**: 2025-01-02  
**👥 Maintainers**: Platform/Blockchain SRE Team

For detailed information, start with the [📋 Documentation Index](./DOCUMENTATION_INDEX.md).
