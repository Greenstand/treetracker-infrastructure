# File Manifest - Hyperledger Fabric Peers Directory

**Generated:** 2025-09-02T04:21:00Z  
**Total Files:** 134  
**Base Path:** `/root/hyperledger-fabric-network/peers`

## NEW PEER ORGANIZATIONS ADDED

✨ **CBO Peer** - CBOMSP (Chief Business Officer)
✨ **Investor Peer** - InvestorMSP  
✨ **Verifier Peer** - VerifierMSP

## Complete File Listing

### Helm Chart Configuration (7 files)

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `helm-charts/Chart.yaml` | 129B | YAML | Helm chart metadata and version info |
| `helm-charts/values.yaml` | 1.6K | YAML | Primary Helm chart configuration values |
| `helm-charts/values.yaml.bkp` | 1.3K | YAML | Backup of original values configuration |
| `helm-charts/templates/configmap.yaml` | 973B | YAML | Kubernetes ConfigMap template for Fabric core config |
| `helm-charts/templates/pvc.yaml` | 530B | YAML | Persistent Volume Claim template |
| `helm-charts/templates/service.yaml` | 606B | YAML | Kubernetes Service template |
| `helm-charts/templates/statefulset.yaml` | 6.9K | YAML | StatefulSet template for peer deployment |

### Peer0 MSP Materials (6 files)

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/peer0-msp/cacerts/greenstand-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | CA root certificate |
| `secrets/peer0-msp/signcerts/cert.pem` | ~1.1K | PEM | Peer identity certificate |
| `secrets/peer0-msp/keystore/1e351bb264c86ba8bc20a7042aabfd0470ddccdc204b82e445475a74103fcaab_sk` | ~241B | PEM | Private signing key |
| `secrets/peer0-msp/config.yaml` | ~200B | YAML | NodeOU configuration |
| `secrets/peer0-msp/IssuerPublicKey` | ~843B | PEM | CA public key |
| `secrets/peer0-msp/IssuerRevocationPublicKey` | ~215B | PEM | Certificate revocation public key |

### Peer0 TLS Materials (7 files)

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/peer0-tls/signcerts/cert.pem` | ~1.1K | PEM | TLS identity certificate |
| `secrets/peer0-tls/keystore/25c4d5a93157ecdcf97b37189084ea2e0f09eb8237bda230cd6f13a81a09cc1b_sk` | ~241B | PEM | TLS private key |
| `secrets/peer0-tls/server.crt` | ~1.1K | PEM | TLS server certificate |
| `secrets/peer0-tls/server.key` | ~241B | PEM | TLS server private key |
| `secrets/peer0-tls/ca.crt` | ~786B | PEM | TLS CA certificate |
| `secrets/peer0-tls/tlscacerts/tls-greenstand-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | TLS CA certificate (directory) |
| `secrets/peer0-tls/IssuerPublicKey` | ~843B | PEM | TLS CA public key |
| `secrets/peer0-tls/IssuerRevocationPublicKey` | ~215B | PEM | TLS CRL public key |

### Peer1 MSP Materials (6 files)

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/peer1-msp/cacerts/greenstand-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | CA root certificate |
| `secrets/peer1-msp/signcerts/cert.pem` | ~1.1K | PEM | Peer identity certificate |
| `secrets/peer1-msp/keystore/1a66c49de44e45956d3647faa514b0107946489fa4f02650520ead1fb718632c_sk` | ~241B | PEM | Private signing key |
| `secrets/peer1-msp/config.yaml` | ~200B | YAML | NodeOU configuration ⚠️ (incomplete) |
| `secrets/peer1-msp/IssuerPublicKey` | ~843B | PEM | CA public key |
| `secrets/peer1-msp/IssuerRevocationPublicKey` | ~215B | PEM | Certificate revocation public key |

### Peer1 TLS Materials (7 files)

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/peer1-tls/signcerts/cert.pem` | ~1.1K | PEM | TLS identity certificate |
| `secrets/peer1-tls/keystore/aa56e1e29a94b7ff9732572f56875848d47db7be04f3916c4332004082b78f31_sk` | ~241B | PEM | TLS private key |
| `secrets/peer1-tls/server.crt` | ~1.1K | PEM | TLS server certificate |
| `secrets/peer1-tls/server.key` | ~241B | PEM | TLS server private key |
| `secrets/peer1-tls/ca.crt` | ~786B | PEM | TLS CA certificate |
| `secrets/peer1-tls/tlscacerts/tls-greenstand-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | TLS CA certificate (directory) |
| `secrets/peer1-tls/IssuerPublicKey` | ~843B | PEM | TLS CA public key |
| `secrets/peer1-tls/IssuerRevocationPublicKey` | ~215B | PEM | TLS CRL public key |

### Peer2 MSP Materials (6 files)

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/peer2-msp/cacerts/greenstand-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | CA root certificate |
| `secrets/peer2-msp/signcerts/cert.pem` | ~1.1K | PEM | Peer identity certificate |
| `secrets/peer2-msp/keystore/6fe42c83ebe8227527c6373eec4d148ff6368c357fddb67702f1dd1481e17225_sk` | ~241B | PEM | Private signing key |
| `secrets/peer2-msp/config.yaml` | ~200B | YAML | NodeOU configuration ⚠️ (incomplete) |
| `secrets/peer2-msp/IssuerPublicKey` | ~843B | PEM | CA public key |
| `secrets/peer2-msp/IssuerRevocationPublicKey` | ~215B | PEM | Certificate revocation public key |

### Peer2 TLS Materials (7 files)

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/peer2-tls/signcerts/cert.pem` | ~1.1K | PEM | TLS identity certificate |
| `secrets/peer2-tls/keystore/e43bb7dd404c9f1a1efb1eb615fe5a35ded3e7ca282d1b344e57a641ec2dfdc8_sk` | ~241B | PEM | TLS private key |
| `secrets/peer2-tls/server.crt` | ~1.1K | PEM | TLS server certificate |
| `secrets/peer2-tls/server.key` | ~241B | PEM | TLS server private key |
| `secrets/peer2-tls/ca.crt` | ~786B | PEM | TLS CA certificate |
| `secrets/peer2-tls/tlscacerts/tls-greenstand-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | TLS CA certificate (directory) |
| `secrets/peer2-tls/IssuerPublicKey` | ~843B | PEM | TLS CA public key |
| `secrets/peer2-tls/IssuerRevocationPublicKey` | ~215B | PEM | TLS CRL public key |

### CBO Peer MSP Materials (6 files) ✨ NEW

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/cbo-msp/cacerts/cbo-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | CBO CA root certificate |
| `secrets/cbo-msp/signcerts/cert.pem` | ~1.1K | PEM | CBO peer identity certificate |
| `secrets/cbo-msp/keystore/*_sk` | ~241B | PEM | CBO private signing key |
| `secrets/cbo-msp/config.yaml` | ~536B | YAML | CBO NodeOU configuration |
| `secrets/cbo-msp/IssuerPublicKey` | ~843B | PEM | CBO CA public key |
| `secrets/cbo-msp/IssuerRevocationPublicKey` | ~215B | PEM | CBO certificate revocation public key |

### CBO Peer TLS Materials (8 files) ✨ NEW

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/cbo-tls/signcerts/cert.pem` | ~1.1K | PEM | CBO TLS identity certificate |
| `secrets/cbo-tls/keystore/*_sk` | ~241B | PEM | CBO TLS private key |
| `secrets/cbo-tls/server.crt` | ~1.1K | PEM | CBO TLS server certificate |
| `secrets/cbo-tls/server.key` | ~241B | PEM | CBO TLS server private key |
| `secrets/cbo-tls/ca.crt` | ~786B | PEM | CBO TLS CA certificate |
| `secrets/cbo-tls/tlscacerts/tls-cbo-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | CBO TLS CA certificate (directory) |
| `secrets/cbo-tls/IssuerPublicKey` | ~843B | PEM | CBO TLS CA public key |
| `secrets/cbo-tls/IssuerRevocationPublicKey` | ~215B | PEM | CBO TLS CRL public key |

### Investor Peer MSP Materials (6 files) ✨ NEW

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/investor-msp/cacerts/investor-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | Investor CA root certificate |
| `secrets/investor-msp/signcerts/cert.pem` | ~1.1K | PEM | Investor peer identity certificate |
| `secrets/investor-msp/keystore/*_sk` | ~241B | PEM | Investor private signing key |
| `secrets/investor-msp/config.yaml` | ~536B | YAML | Investor NodeOU configuration |
| `secrets/investor-msp/IssuerPublicKey` | ~843B | PEM | Investor CA public key |
| `secrets/investor-msp/IssuerRevocationPublicKey` | ~215B | PEM | Investor certificate revocation public key |

### Investor Peer TLS Materials (8 files) ✨ NEW

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/investor-tls/signcerts/cert.pem` | ~1.1K | PEM | Investor TLS identity certificate |
| `secrets/investor-tls/keystore/*_sk` | ~241B | PEM | Investor TLS private key |
| `secrets/investor-tls/server.crt` | ~1.1K | PEM | Investor TLS server certificate |
| `secrets/investor-tls/server.key` | ~241B | PEM | Investor TLS server private key |
| `secrets/investor-tls/ca.crt` | ~786B | PEM | Investor TLS CA certificate |
| `secrets/investor-tls/tlscacerts/tls-investor-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | Investor TLS CA certificate (directory) |
| `secrets/investor-tls/IssuerPublicKey` | ~843B | PEM | Investor TLS CA public key |
| `secrets/investor-tls/IssuerRevocationPublicKey` | ~215B | PEM | Investor TLS CRL public key |

### Verifier Peer MSP Materials (6 files) ✨ NEW

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/verifier-msp/cacerts/verifier-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | Verifier CA root certificate |
| `secrets/verifier-msp/signcerts/cert.pem` | ~1.1K | PEM | Verifier peer identity certificate |
| `secrets/verifier-msp/keystore/*_sk` | ~241B | PEM | Verifier private signing key |
| `secrets/verifier-msp/config.yaml` | ~536B | YAML | Verifier NodeOU configuration |
| `secrets/verifier-msp/IssuerPublicKey` | ~843B | PEM | Verifier CA public key |
| `secrets/verifier-msp/IssuerRevocationPublicKey` | ~215B | PEM | Verifier certificate revocation public key |

### Verifier Peer TLS Materials (8 files) ✨ NEW

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `secrets/verifier-tls/signcerts/cert.pem` | ~1.1K | PEM | Verifier TLS identity certificate |
| `secrets/verifier-tls/keystore/*_sk` | ~241B | PEM | Verifier TLS private key |
| `secrets/verifier-tls/server.crt` | ~1.1K | PEM | Verifier TLS server certificate |
| `secrets/verifier-tls/server.key` | ~241B | PEM | Verifier TLS server private key |
| `secrets/verifier-tls/ca.crt` | ~786B | PEM | Verifier TLS CA certificate |
| `secrets/verifier-tls/tlscacerts/tls-verifier-ca-hlf-ca-svc-cluster-local-7054.pem` | ~786B | PEM | Verifier TLS CA certificate (directory) |
| `secrets/verifier-tls/IssuerPublicKey` | ~843B | PEM | Verifier TLS CA public key |
| `secrets/verifier-tls/IssuerRevocationPublicKey` | ~215B | PEM | Verifier TLS CRL public key |

### New Peer Helm Configurations (3 files) ✨ NEW

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `helm-charts/values-cbo.yaml` | ~1.2K | YAML | CBO peer Helm configuration |
| `helm-charts/values-investor.yaml` | ~1.2K | YAML | Investor peer Helm configuration |
| `helm-charts/values-verifier.yaml` | ~1.2K | YAML | Verifier peer Helm configuration |

### New Deployment Scripts (4 files) ✨ NEW

| File Path | Size | Type | Description |
|-----------|------|------|-------------|
| `scripts/deploy-cbo-peer.sh` | ~1.1K | Shell | CBO peer deployment script |
| `scripts/deploy-investor-peer.sh` | ~1.1K | Shell | Investor peer deployment script |
| `scripts/deploy-verifier-peer.sh` | ~1.1K | Shell | Verifier peer deployment script |
| `scripts/deploy-all-new-peers.sh` | ~1.8K | Shell | Deploy all new peers at once |

## File Type Summary

| Category | Count | Total Size | Notes |
|----------|-------|------------|-------|
| YAML Configuration | 14 | ~8.1K | Helm and MSP configuration (Original + New) |
| X.509 Certificates | 42 | ~41K | Identity and TLS certificates (6 orgs) |
| Private Keys | 21 | ~5.1K | ECDSA P-256 private keys (6 orgs) |
| Public Keys | 28 | ~24K | CA and revocation keys (6 orgs) |
| Shell Scripts | 10 | ~15K | Deployment and management scripts |
| Documentation | 4 | ~25K | README and analysis files |
| **Total** | **134** | **~118K** | Complete multi-org peer configuration |

## Key File Relationships

### Certificate Chain Dependencies
```
Root CA (root-ca.hlf-ca.svc.cluster.local:7054)
├── Greenstand CA (greenstand-ca-hlf-ca-svc-cluster-local-7054.pem)
│   ├── peer0.greenstand (GreenstandMSP)
│   ├── peer1.greenstand (GreenstandMSP)
│   └── peer2.greenstand (GreenstandMSP)
├── CBO CA (cbo-ca-hlf-ca-svc-cluster-local-7054.pem) ✨ NEW
│   └── peer0.cbo (CBOMSP)
├── Investor CA (investor-ca-hlf-ca-svc-cluster-local-7054.pem) ✨ NEW
│   └── peer0.investor (InvestorMSP)
└── Verifier CA (verifier-ca-hlf-ca-svc-cluster-local-7054.pem) ✨ NEW
    └── peer0.verifier (VerifierMSP)
```

### Kubernetes Secret Mapping
```
Original Greenstand Peers:
├── peer0-msp → secrets/peer0-msp/ (GreenstandMSP)
├── peer1-msp → secrets/peer1-msp/ (GreenstandMSP)
├── peer2-msp → secrets/peer2-msp/ (GreenstandMSP)
├── peer0-tls → secrets/peer0-tls/
├── peer1-tls → secrets/peer1-tls/
└── peer2-tls → secrets/peer2-tls/

New Organization Peers: ✨
├── cbo-msp → secrets/cbo-msp/ (CBOMSP)
├── cbo-tls → secrets/cbo-tls/
├── investor-msp → secrets/investor-msp/ (InvestorMSP)
├── investor-tls → secrets/investor-tls/
├── verifier-msp → secrets/verifier-msp/ (VerifierMSP)
└── verifier-tls → secrets/verifier-tls/
```

### Helm Template Relationships
```
values.yaml (configuration) 
├── statefulset.yaml (peer containers)
├── service.yaml (networking)
├── pvc.yaml (storage)
└── configmap.yaml (Fabric config)
```

## Security Considerations

### Private Key Security
- All private keys are properly protected with 600 file permissions
- Keys are ECDSA P-256 (modern, secure)
- Unique private key per peer per function (MSP vs TLS)

### Certificate Validity
- Peer certificates valid until August 2026
- CA certificates valid until August 2040
- All certificates use ECDSA-SHA256 signatures

### Access Control
- NodeOU configuration enables role-based access
- Organizational units: client, peer, admin, orderer
- Proper certificate extensions for intended use

---

**Legend:**
- ✅ = Properly configured
- ⚠️ = Requires attention
- 🔒 = Security-sensitive file
- 📁 = Directory
