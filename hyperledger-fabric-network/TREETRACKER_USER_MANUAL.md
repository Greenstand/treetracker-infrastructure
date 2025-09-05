# Hyperledger Fabric Treetracker Network - User Manual

## Table of Contents
1. [Overview](#overview)
2. [Network Architecture](#network-architecture)
3. [User Roles and Permissions](#user-roles-and-permissions)
4. [Getting Started](#getting-started)
5. [Basic Operations](#basic-operations)
6. [Channel Operations](#channel-operations)
7. [Tree Tracking Operations](#tree-tracking-operations)
8. [Monitoring and Status Checking](#monitoring-and-status-checking)
9. [Troubleshooting](#troubleshooting)
10. [FAQ](#faq)

---

## Overview

### What is the Treetracker Network?

The Hyperledger Fabric Treetracker Network is a blockchain-based solution designed to track and verify tree planting activities across multiple organizations. It provides transparent, immutable records of tree lifecycle events, from planting to maturity, enabling trust among stakeholders in reforestation projects.

### Key Features
- **Multi-Organization Trust**: Secure collaboration between Greenstand, CBOs, Investors, and Verifiers
- **Transparent Tracking**: Immutable records of tree planting, growth, and verification events
- **Decentralized Verification**: Independent verification by multiple parties
- **Scalable Architecture**: Kubernetes-based deployment supporting high availability
- **Data Integrity**: Cryptographic proof of all tree-related transactions

### Use Cases
- **Reforestation Projects**: Track progress of tree planting initiatives
- **Carbon Credit Verification**: Provide verifiable data for carbon credit calculations
- **Impact Measurement**: Measure and report environmental impact
- **Funding Transparency**: Enable transparent use of funding for tree planting
- **Supply Chain Tracking**: Track trees from seedling to mature forest

---

## Network Architecture

### Organizations

The network consists of four main organizations:

#### 1. **Greenstand** (Primary Organization)
- **Role**: Primary tree planting organization and network coordinator
- **MSP ID**: `GreenstandMSP`
- **Peer Nodes**: 3 (peer0, peer1, peer2)
- **Responsibilities**:
  - Tree planting coordination
  - Initial tree registration
  - Data collection and management
  - Network governance

#### 2. **Community-Based Organizations (CBO)**
- **Role**: Local tree planting and maintenance
- **MSP ID**: `CBOMSP`
- **Peer Nodes**: 2 (peer0-cbo, peer1-cbo)
- **Responsibilities**:
  - Local tree planting activities
  - Community engagement
  - Ground-level monitoring
  - Local verification

#### 3. **Investors**
- **Role**: Funding and financial oversight
- **MSP ID**: `InvestorMSP`
- **Peer Nodes**: 2 (peer0-investor, peer1-investor)
- **Responsibilities**:
  - Project funding
  - Financial tracking
  - ROI monitoring
  - Investment verification

#### 4. **Verifiers**
- **Role**: Independent verification and auditing
- **MSP ID**: `VerifierMSP`
- **Peer Nodes**: 1 (peer0-verifier)
- **Responsibilities**:
  - Independent tree verification
  - Data validation
  - Audit trail maintenance
  - Compliance checking

### Network Infrastructure

#### Consensus Layer
- **5 Orderer Nodes**: RAFT consensus algorithm
- **High Availability**: Tolerates up to 2 node failures
- **Throughput**: Optimized for tree tracking transaction volumes

#### Certificate Authority
- **Root CA**: Primary certificate authority
- **Organization CAs**: Separate CA for each organization
- **TLS Security**: All communications encrypted

#### Channels
- **Public Channel** (`treechannel`): Main tree tracking activities
- **Private Channels**: Organization-specific sensitive data

---

## User Roles and Permissions

### Administrator Roles

#### Network Administrator
- **Scope**: Network-wide operations
- **Permissions**:
  - Create and manage channels
  - Deploy chaincode
  - Manage certificates
  - Monitor network health
- **Access Level**: Full network access

#### Organization Administrator
- **Scope**: Organization-specific operations
- **Permissions**:
  - Manage organization peers
  - Add/remove users
  - Approve transactions
  - Configure organization policies

### Operational Roles

#### Tree Planter
- **Organization**: Greenstand, CBO
- **Permissions**:
  - Register new trees
  - Update tree status
  - Submit planting reports
  - View assigned trees

#### Verifier User
- **Organization**: Verifiers
- **Permissions**:
  - Verify tree records
  - Submit verification reports
  - Access verification history
  - Generate audit reports

#### Investor User
- **Organization**: Investors
- **Permissions**:
  - View funded projects
  - Access financial reports
  - Monitor investment ROI
  - Approve funding releases

#### Community Member
- **Organization**: CBO
- **Permissions**:
  - View local tree data
  - Report tree status
  - Submit community feedback
  - Access local reports

---

## Getting Started

### Prerequisites

Before using the Treetracker Network, ensure you have:

1. **Network Access**: VPN or direct network connectivity to the Kubernetes cluster
2. **Credentials**: Valid certificates for your organization
3. **Tools**: kubectl, Fabric CLI tools (optional for advanced operations)
4. **Browser**: Modern web browser for Blockchain Explorer access

### Initial Setup

#### Step 1: Verify Network Connectivity
```bash
# Check if you can access the cluster
kubectl get pods -n hlf-greenstand-peer

# Expected output: List of running Greenstand peer pods
```

#### Step 2: Access Blockchain Explorer
1. Open your web browser
2. Navigate to the Blockchain Explorer URL (provided by network admin)
3. Log in with your organization credentials

#### Step 3: Verify Your Organization Access
```bash
# Check your organization's peer status
kubectl exec -n hlf-<your-org>-peer <peer-name> -- peer version

# Example for Greenstand:
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer version
```

### Quick Start Checklist

- [ ] Network connectivity verified
- [ ] Organization credentials obtained
- [ ] Blockchain Explorer accessible
- [ ] Peer connectivity confirmed
- [ ] Channel access verified

---

## Basic Operations

### Viewing Network Status

#### Check All Network Components
```bash
# Check all network pods
kubectl get pods --all-namespaces | grep -E "(greenstand|cbo|investor|verifier|orderer)"

# Check network services
kubectl get services --all-namespaces | grep hlf
```

#### Monitor Network Health
```bash
# Run network health check
cd /root/hyperledger-fabric-network
./diagnose-network.sh

# Check specific organization status
kubectl describe pods -n hlf-greenstand-peer
```

### Accessing Logs

#### View Peer Logs
```bash
# View Greenstand peer logs
kubectl logs -n hlf-greenstand-peer peer0-0 -f

# View CBO peer logs  
kubectl logs -n hlf-cbo-peer peer0-cbo-0 -f

# View orderer logs
kubectl logs -n hlf-orderer orderer0-0 -f
```

#### View Certificate Authority Logs
```bash
# View CA logs
kubectl logs -n hlf-ca greenstand-ca-<pod-suffix> -f
```

### Basic Troubleshooting Commands

#### Restart Pods
```bash
# Restart a specific peer
kubectl delete pod -n hlf-greenstand-peer peer0-0

# Restart CA service
kubectl delete pod -n hlf-ca greenstand-ca-<pod-suffix>
```

#### Check Storage Status
```bash
# Check persistent volumes
kubectl get pv | grep hlf

# Check storage claims
kubectl get pvc -n hlf-greenstand-peer
```

---

## Channel Operations

### Understanding Channels

#### Public Channel (`treechannel`)
- **Purpose**: Main tree tracking activities
- **Participants**: All organizations
- **Data**: Tree registration, growth updates, verification records
- **Access**: Read/write for all members

#### Private Channels
- **Purpose**: Organization-specific sensitive data
- **Participants**: Specific organizations only
- **Data**: Internal processes, sensitive financial data
- **Access**: Restricted to channel members

### Channel Management

#### List Available Channels
```bash
# List channels for Greenstand peer
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer channel list

# Expected output: Channels peers has joined: treechannel
```

#### Check Channel Status
```bash
# Get channel information
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer channel getinfo -c treechannel
```

#### Join a Channel (Admin Only)
```bash
# Join peer to channel (requires channel block)
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer channel join -b treechannel.block
```

### Channel Policies

#### Endorsement Policies
- **Majority Policy**: Requires majority organization approval
- **All Policy**: Requires all organizations to endorse
- **Custom Policy**: Organization-specific requirements

#### Access Policies
- **Read Access**: All channel members can read data
- **Write Access**: Requires proper endorsement
- **Admin Access**: Channel configuration changes

---

## Tree Tracking Operations

### Tree Registration

#### Register a New Tree
The tree registration process involves multiple steps and organizations:

1. **Initial Registration** (Greenstand/CBO)
2. **Location Verification** (GPS coordinates)
3. **Species Confirmation** (Botanical verification)
4. **Funding Assignment** (Investor validation)
5. **Verification Schedule** (Verifier assignment)

#### Tree Data Structure
```json
{
  "treeId": "TRK-2024-001234",
  "species": "Quercus alba",
  "location": {
    "latitude": -1.2921,
    "longitude": 36.8219,
    "altitude": 1800,
    "country": "Kenya",
    "region": "Nairobi"
  },
  "plantingDate": "2024-09-05T10:30:00Z",
  "plantedBy": "CBO-Kenya-001",
  "fundedBy": "INVESTOR-GREEN-FUND-01",
  "status": "planted",
  "verificationSchedule": "monthly",
  "assignedVerifier": "VERIFIER-INDEPENDENT-01"
}
```

### Tree Status Updates

#### Available Status Values
- `seedling`: Recently planted, under 6 months
- `growing`: Established tree, 6-24 months
- `mature`: Established tree, over 2 years
- `verified`: Independently verified survival
- `lost`: Tree did not survive (requires verification)
- `harvested`: Tree was harvested (where applicable)

#### Update Tree Status
```bash
# Example status update (via chaincode)
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer chaincode invoke \
  -o orderer0.hlf-orderer.svc.cluster.local:7050 \
  --tls --cafile /var/hyperledger/peer/orderer-ca-cert.pem \
  -C treechannel -n treetracker \
  -c '{"function":"updateTreeStatus","Args":["TRK-2024-001234","growing"]}'
```

### Verification Process

#### Verification Types
1. **Remote Verification**: Satellite/drone imagery
2. **Ground Verification**: Physical site inspection
3. **Community Verification**: Local community confirmation
4. **Scientific Verification**: Botanical/ecological assessment

#### Submit Verification Report
```json
{
  "verificationId": "VER-2024-001234-01",
  "treeId": "TRK-2024-001234",
  "verifierOrg": "VerifierMSP",
  "verificationDate": "2024-09-05T14:30:00Z",
  "verificationMethod": "ground_inspection",
  "result": "verified",
  "confidence": 95,
  "evidence": {
    "photos": ["photo1.jpg", "photo2.jpg"],
    "measurements": {
      "height": 1.2,
      "diameter": 0.05,
      "health": "good"
    },
    "gpsAccuracy": 3.0
  }
}
```

### Query Operations

#### Query Tree by ID
```bash
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer chaincode query \
  -C treechannel -n treetracker \
  -c '{"function":"getTree","Args":["TRK-2024-001234"]}'
```

#### Query Trees by Location
```bash
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer chaincode query \
  -C treechannel -n treetracker \
  -c '{"function":"getTreesByLocation","Args":["Kenya", "Nairobi"]}'
```

#### Query Verification History
```bash
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer chaincode query \
  -C treechannel -n treetracker \
  -c '{"function":"getVerificationHistory","Args":["TRK-2024-001234"]}'
```

---

## Monitoring and Status Checking

### Network Health Monitoring

#### Automated Health Checks
```bash
# Run comprehensive network check
cd /root/hyperledger-fabric-network/public-channels
./check-public-channels-status.sh
```

#### Manual Health Verification
```bash
# Check peer connectivity
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer version

# Check channel membership
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer channel list

# Check chaincode installation
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer lifecycle chaincode queryinstalled
```

### Performance Monitoring

#### Transaction Throughput
- Monitor transaction rates via Blockchain Explorer
- Check peer logs for performance metrics
- Review orderer batch processing efficiency

#### Resource Utilization
```bash
# Check pod resource usage
kubectl top pods -n hlf-greenstand-peer

# Check node resource utilization
kubectl top nodes

# Check storage usage
kubectl get pvc -n hlf-greenstand-peer
```

### Alerting and Notifications

#### Key Metrics to Monitor
- **Peer Status**: All peers operational
- **Channel Health**: Channels accessible and functional
- **Transaction Success Rate**: >95% transaction success
- **Certificate Expiry**: Certificates valid and not expiring soon
- **Storage Usage**: <80% storage utilization

#### Setting Up Alerts
1. Configure monitoring tools (Prometheus/Grafana)
2. Set threshold values for critical metrics
3. Configure notification channels (email, Slack)
4. Test alert mechanisms regularly

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Peer Cannot Connect to Network
**Symptoms:**
- Peer logs show connection errors
- Cannot execute peer commands
- Channel operations fail

**Solutions:**
```bash
# Check peer status
kubectl describe pod -n hlf-greenstand-peer peer0-0

# Restart peer pod
kubectl delete pod -n hlf-greenstand-peer peer0-0

# Verify network policies
kubectl get networkpolicy -n hlf-greenstand-peer
```

#### Issue 2: Certificate Errors
**Symptoms:**
- TLS handshake failures
- Certificate validation errors
- MSP errors in logs

**Solutions:**
```bash
# Check certificate validity
kubectl exec -n hlf-greenstand-peer peer0-0 -- \
  openssl x509 -in /var/hyperledger/peer/msp/signcerts/cert.pem -text -noout

# Regenerate certificates if needed
cd /root/hyperledger-fabric-network
./fix-tls-certificates.sh
```

#### Issue 3: Channel Access Issues
**Symptoms:**
- Cannot join channels
- Channel queries fail
- Transaction endorsement failures

**Solutions:**
```bash
# Verify channel membership
kubectl exec -n hlf-greenstand-peer peer0-0 -- peer channel list

# Re-join channel if necessary
kubectl exec -n hlf-greenstand-peer peer0-0 -- \
  peer channel join -b treechannel.block

# Check channel configuration
kubectl exec -n hlf-greenstand-peer peer0-0 -- \
  peer channel getinfo -c treechannel
```

#### Issue 4: Storage Issues
**Symptoms:**
- Pods stuck in pending state
- Storage mount failures
- Out of storage errors

**Solutions:**
```bash
# Check persistent volume status
kubectl get pv | grep hlf

# Check storage claims
kubectl get pvc -n hlf-greenstand-peer

# Clean up old data if necessary (CAUTION)
kubectl exec -n hlf-greenstand-peer peer0-0 -- df -h
```

### Diagnostic Commands

#### Comprehensive Network Diagnosis
```bash
# Full network analysis
cd /root/hyperledger-fabric-network
./diagnose-network.sh

# Check specific component
kubectl get all -n hlf-greenstand-peer
```

#### Log Analysis
```bash
# Search for specific errors
kubectl logs -n hlf-greenstand-peer peer0-0 | grep -i error

# Export logs for analysis
kubectl logs -n hlf-greenstand-peer peer0-0 > peer0-logs.txt
```

### Getting Help

#### Internal Resources
- Network Administrator: Contact your organization's network admin
- Documentation: Check `/root/hyperledger-fabric-network/docs/`
- Status Reports: Review latest status reports in the root directory

#### External Resources
- [Hyperledger Fabric Documentation](https://hyperledger-fabric.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- Community Forums and Support Channels

---

## FAQ

### General Questions

**Q: How often should I check the network status?**
A: For normal operations, checking once daily is sufficient. For critical periods or after maintenance, check more frequently.

**Q: Can I access the network from outside the organization?**
A: Access is restricted by network policies and requires proper VPN connectivity and certificates.

**Q: How long are tree records retained?**
A: Tree records are permanent on the blockchain. Historical data is available indefinitely.

### Technical Questions

**Q: What happens if a peer goes down?**
A: The network continues to operate with remaining peers. The downed peer will sync automatically when restored.

**Q: How do I backup my organization's data?**
A: Peer ledger data is automatically backed up via persistent storage. Follow the backup procedures in the operational guide.

**Q: Can I run custom queries on the tree data?**
A: Yes, using the chaincode query functions or through the Blockchain Explorer interface.

### Operational Questions

**Q: How do I report a problem tree or incorrect data?**
A: Submit a verification request through your organization's designated process. Verifiers will investigate and update records as needed.

**Q: What's the process for adding new users to the network?**
A: Contact your organization administrator who can generate new certificates and configure access permissions.

**Q: How are disputes resolved on the network?**
A: Disputes follow the governance model defined in the network policies, typically involving verification by multiple parties.

---

## Appendices

### Appendix A: Network Endpoints

#### Peer Endpoints
- Greenstand: `peer0.hlf-greenstand-peer.svc.cluster.local:7051`
- CBO: `peer0-cbo.hlf-cbo-peer.svc.cluster.local:7051`
- Investor: `peer0-investor.hlf-investor-peer.svc.cluster.local:7051`
- Verifier: `peer0-verifier.hlf-verifier-peer.svc.cluster.local:7051`

#### Orderer Endpoints
- `orderer0.hlf-orderer.svc.cluster.local:7050`
- `orderer1.hlf-orderer.svc.cluster.local:7050`
- `orderer2.hlf-orderer.svc.cluster.local:7050`
- `orderer3.hlf-orderer.svc.cluster.local:7050`
- `orderer4.hlf-orderer.svc.cluster.local:7050`

#### Certificate Authority Endpoints
- Root CA: `root-ca.hlf-ca.svc.cluster.local:7054`
- Greenstand CA: `greenstand-ca.hlf-ca.svc.cluster.local:7054`
- CBO CA: `cbo-ca.hlf-ca.svc.cluster.local:7054`
- Investor CA: `investor-ca.hlf-ca.svc.cluster.local:7054`
- Verifier CA: `verifier-ca.hlf-ca.svc.cluster.local:7054`

### Appendix B: Command Reference

See the Integration Manual for complete API and command references.

---

**Document Version**: 1.0  
**Last Updated**: September 5, 2025  
**Next Review**: December 2025  

**Support Contact**: network-admin@treetracker.org
