# File Manifest - Hyperledger Fabric Peers Directory

**Generated:** 2025-09-02T01:05:31Z  
**Total Files:** 49  
**Base Path:** `/root/hyperledger-fabric-network/peers`

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

## File Type Summary

| Category | Count | Total Size | Notes |
|----------|-------|------------|-------|
| YAML Configuration | 8 | ~4.5K | Helm and MSP configuration |
| X.509 Certificates | 18 | ~17K | Identity and TLS certificates |
| Private Keys | 9 | ~2.2K | ECDSA P-256 private keys |
| Public Keys | 12 | ~10K | CA and revocation keys |
| **Total** | **49** | **~34K** | Complete peer configuration |

## Key File Relationships

### Certificate Chain Dependencies
```
CA Root (greenstand-ca-hlf-ca-svc-cluster-local-7054.pem)
├── peer0.greenstand (MSP + TLS certificates)
├── peer1.greenstand (MSP + TLS certificates)
└── peer2.greenstand (MSP + TLS certificates)
```

### Kubernetes Secret Mapping
```
Peer MSP Secrets:
├── peer0-msp → secrets/peer0-msp/
├── peer1-msp → secrets/peer1-msp/
└── peer2-msp → secrets/peer2-msp/

Peer TLS Secrets:
├── peer0-tls → secrets/peer0-tls/
├── peer1-tls → secrets/peer1-tls/
└── peer2-tls → secrets/peer2-tls/
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
