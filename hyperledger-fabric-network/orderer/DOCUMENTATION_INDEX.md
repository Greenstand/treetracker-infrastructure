# Orderer Infrastructure Documentation Index

This index provides a comprehensive overview of all documentation, scripts, and policies for the Hyperledger Fabric orderer infrastructure on Kubernetes.

## 📋 Quick Navigation

| Document | Purpose | Audience | Status |
|----------|---------|----------|--------|
| [TECHNICAL_SPECS.md](#technical-specifications) | Architecture & technical design | Platform/SRE Engineers | ✅ Complete |
| [OPERATIONAL_PROCEDURES.md](#operational-procedures) | Day-2 operations & runbooks | Operations Teams | ✅ Complete |
| [SECURITY_PROCEDURES.md](#security-procedures) | Security controls & hardening | Security Engineers | ✅ Complete |
| [scripts/check.sh](#health-check-script) | One-click health validation | All Teams | ✅ Complete |
| [policies/kyverno/](#security-policies) | Admission control policies | Security/Platform Teams | ✅ Complete |

---

## 📖 Documentation Overview

### Technical Specifications
**File**: `TECHNICAL_SPECS.md`
**Purpose**: Complete technical reference for orderer infrastructure architecture
**Contents**:
- Kubernetes resource specifications (StatefulSet, Services, PVC, RBAC)
- Raft consensus configuration and requirements
- Genesis block management and structure
- MSP and TLS secret structure for orderer identity
- Network ports, resource sizing, and security contexts
- Integration points with peer organizations
- Scaling, high availability, and known issues

**Key Configuration**:
- Namespace: `orderer`
- Chart Path: `./helm/orderer`
- Labels: `app.kubernetes.io/part-of=hyperledger-fabric`
- Consensus: Raft-based ordering service

---

### Operational Procedures
**File**: `OPERATIONAL_PROCEDURES.md`
**Purpose**: Day-2 operations runbooks and maintenance procedures
**Contents**:
- Deployment and upgrade procedures for orderer cluster
- Raft consensus operations and health monitoring
- Genesis block management and updates
- MSP/TLS secret management and rotation
- Backup, restore, and disaster recovery
- Adding/removing orderer nodes safely
- Troubleshooting consensus, connectivity, and storage issues

**Quick Commands**:
```bash
# Deploy orderer
helm upgrade --install fabric-orderer "./helm/orderer" -n orderer -f values-orderer.yaml

# Check consensus health
kubectl -n orderer logs fabric-orderer-0 | grep -i "raft\|leader"

# Validate secrets
kubectl -n orderer describe secret fabric-orderer-msp
```

---

### Security Procedures
**File**: `SECURITY_PROCEDURES.md`
**Purpose**: Security controls, hardening, and compliance guidance
**Contents**:
- Consensus security and Raft cluster protection
- Identity and Access Management (RBAC, ServiceAccounts)
- Network security with mTLS and NetworkPolicies
- Genesis block security and integrity
- Certificate management and rotation workflows
- Pod and container hardening (non-root, seccomp, capabilities)
- Incident response for consensus and certificate issues
- Compliance mapping and periodic security tasks

**Security Objectives**:
- Consensus Integrity: Protect Raft mechanism from attacks
- Transaction Ordering: Secure ordering without content modification
- Network Isolation: Secure cluster from unauthorized access
- Genesis Block: Protect network bootstrap configuration

---

## 🔧 Scripts and Tools

### Health Check Script
**File**: `scripts/check.sh`
**Purpose**: One-click health validation for orderer infrastructure
**Modes**:
- `summary` (default): Basic pods, services, PVCs, consensus leader check
- `deep`: Comprehensive check including certificates, secrets, Genesis block
- `secrets-only`: MSP/TLS secrets structure and cert/key matching
- `consensus-only`: Raft consensus health and leadership only

**Usage**:
```bash
# Quick health check
./scripts/check.sh

# Full validation
./scripts/check.sh deep

# Consensus validation only
./scripts/check.sh consensus-only
```

**Features**:
- Color-coded output (errors, warnings, success)
- Raft consensus leadership detection
- Genesis block validation
- MSP secret structure validation
- TLS certificate/private key pair verification
- Certificate expiration checking (30/90 day warnings)

---

## 🛡️ Security Policies

### Kyverno Admission Policies
**Directory**: `policies/kyverno/`
**Purpose**: Enforce security baselines and validation via admission control

#### Policy Catalog

| Policy | File | Purpose | Enforcement |
|--------|------|---------|-------------|
| **Image Security** | `disallow-latest-tags.yaml` | Block `:latest` image tags | 🔒 Enforce |
| **Container Security** | `enforce-security-context.yaml` | Non-root, seccomp, capabilities | 🔒 Enforce |
| **Secret Validation** | `validate-orderer-secrets.yaml` | Validate MSP/TLS structure | 🔒 Enforce |
| **Genesis Block** | `validate-genesis-block.yaml` | Validate Genesis block ConfigMap | 🔒 Enforce |
| **Network Security** | `restrict-network-access.yaml` | Generate NetworkPolicies | 📝 Generate |

#### Installation
```bash
# Install Kyverno (if not present)
kubectl apply -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml

# Apply all policies
kubectl apply -f policies/kyverno/

# Verify policies
kubectl get cpol
```

#### Policy Details

**disallow-latest-tags.yaml**
- Prevents deployment of containers with `:latest` tags
- Scope: Pod, Deployment, StatefulSet in orderer namespace
- Rationale: Ensures reproducible deployments

**enforce-security-context.yaml**
- Enforces non-root execution (`runAsNonRoot: true`)
- Requires RuntimeDefault seccomp profile
- Drops all Linux capabilities
- Prevents privilege escalation

**validate-orderer-secrets.yaml**
- MSP secret (fabric-orderer-msp) must contain: cacerts, signcerts, keystore, config.yaml
- TLS secret (fabric-orderer-tls) must contain: tls.crt, tls.key, ca.crt
- Validates at secret creation/update time

**validate-genesis-block.yaml**
- ConfigMap fabric-genesis-block must contain genesis.block data
- StatefulSet fabric-orderer must mount Genesis block ConfigMap
- Ensures Genesis block consistency

**restrict-network-access.yaml**
- Auto-generates NetworkPolicy for orderer namespace
- Allows: Peers (7050), Inter-orderer Raft (7050), Monitoring (9443)
- Default deny for all other ingress traffic

---

## 🏗️ Architecture Context

### Orderer Deployment
```
orderer/               # Orderer namespace
├── fabric-orderer-0, fabric-orderer-1, fabric-orderer-2  # Raft cluster (3 nodes)
├── fabric-orderer-msp, fabric-orderer-tls (secrets)      # Identity and TLS
├── fabric-genesis-block (configmap)                      # Network bootstrap
└── fabric-orderer, fabric-orderer-headless (services)    # Peer access + discovery
```

### Consensus Architecture
- **Raft Consensus**: 3, 5, or 7 orderers for fault tolerance
- **Leader Election**: One active leader, others follow
- **Log Replication**: Transaction ordering replicated across cluster
- **Fault Tolerance**: (n-1)/2 failures tolerated

### Integration Points
- **Peer Connections**: Peers submit transactions on port 7050
- **Genesis Block**: Network initialization and configuration
- **Channel Operations**: Channel creation and configuration updates
- **Certificate Authority**: Enrollment and certificate renewal
- **Operations/Metrics**: Health and metrics endpoint on port 9443

---

## 📚 Reference Materials

### External Documentation
- [Hyperledger Fabric Orderer Documentation](https://hyperledger-fabric.readthedocs.io/en/latest/orderer_deploy.html)
- [Raft Consensus Algorithm](https://raft.github.io/)
- [Fabric Genesis Block Configuration](https://hyperledger-fabric.readthedocs.io/en/latest/config.html)
- [Kubernetes StatefulSet Best Practices](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
- [Kyverno Policy Library](https://kyverno.io/policies/)

### Related Network Components
- **Peers**: `../peers/` - Peer organization configuration
- **CA**: `../ca/` - Certificate Authority setup
- **Network Scripts**: `../scripts/` - Network deployment automation
- **Monitoring**: `../monitoring/` - Certificate monitoring and alerting

---

## 🚀 Getting Started

### New Team Members
1. Read [TECHNICAL_SPECS.md](./TECHNICAL_SPECS.md) for architecture overview
2. Review [OPERATIONAL_PROCEDURES.md](./OPERATIONAL_PROCEDURES.md) for common tasks
3. Run `./scripts/check.sh deep` to validate current deployment
4. Check [SECURITY_PROCEDURES.md](./SECURITY_PROCEDURES.md) for security guidelines

### Emergency Procedures
1. **Consensus Issues**: Follow troubleshooting in OPERATIONAL_PROCEDURES.md section 10.2
2. **Certificate Issues**: Use scripts/check.sh secrets-only + SECURITY_PROCEDURES.md section 13
3. **Genesis Block Issues**: Check OPERATIONAL_PROCEDURES.md section 4 and SECURITY_PROCEDURES.md section 13.3
4. **Network Partitions**: Follow OPERATIONAL_PROCEDURES.md section 15.1

### Common Tasks Quick Reference
| Task | Command | Documentation |
|------|---------|---------------|
| Health Check | `./scripts/check.sh` | [Scripts](#health-check-script) |
| Deploy Orderer | `helm upgrade --install fabric-orderer ./helm/orderer -n orderer -f values-orderer.yaml` | [Operations](./OPERATIONAL_PROCEDURES.md#1-deploy-or-upgrade-orderer) |
| Check Consensus | `./scripts/check.sh consensus-only` | [Operations](./OPERATIONAL_PROCEDURES.md#3-raft-consensus-operations) |
| Rotate Certs | Follow cert rotation workflow | [Security](./SECURITY_PROCEDURES.md#10-certificate-and-key-management) |
| Scale Orderer | `kubectl -n orderer scale sts fabric-orderer --replicas=5` | [Operations](./OPERATIONAL_PROCEDURES.md#91-adding-orderer-nodes) |
| View Logs | `kubectl -n orderer logs fabric-orderer-0 --tail=200` | [Operations](./OPERATIONAL_PROCEDURES.md#111-basic-health) |

---

## 📞 Support and Contacts

### Documentation Ownership
- **Technical Specifications**: Platform/Blockchain SRE Team  
- **Operational Procedures**: Operations Team
- **Security Procedures**: Security Engineering Team
- **Scripts and Policies**: Platform Team

### Escalation Path
1. **Consensus Failures**: Immediate escalation to SRE team
2. **Certificate Issues**: Security team consultation required
3. **Network Partitions**: Coordinate with infrastructure team
4. **Genesis Block Issues**: Require network-wide coordination

### Update Process
1. Create PR with documentation changes
2. Review with appropriate team owners
3. Update version numbers and change dates
4. Test changes with validation scripts
5. Merge after approval

**Last Updated**: 2025-01-02  
**Version**: 1.0  
**Maintainers**: Platform/Blockchain SRE

For detailed information, start with the [📋 Documentation Index](./DOCUMENTATION_INDEX.md).
