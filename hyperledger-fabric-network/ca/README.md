# Hyperledger Fabric Certificate Authority (CA) Documentation

This directory contains the complete Certificate Authority infrastructure for the Hyperledger Fabric network, including Root CA, Intermediate CAs, deployment scripts, and management tools.

## Overview

The CA infrastructure provides:
- **Root CA**: Central certificate authority for the network
- **Intermediate CAs**: Organization-specific certificate authorities (CBO, Investor, Verifier, Greenstand)
- **Automated enrollment**: Scripts for identity registration and certificate enrollment
- **Kubernetes deployment**: Helm charts for scalable CA deployment
- **Backup/restore**: Complete CA data backup and restoration capabilities

## Directory Structure

```
ca/
├── helm-charts/                    # Helm deployment charts
│   ├── root-ca/                   # Root CA deployment
│   ├── cbo-ca/                    # CBO organization CA
│   ├── investor-ca/               # Investor organization CA
│   ├── verifier-ca/               # Verifier organization CA
│   ├── greenstand-ca/             # Greenstand organization CA
│   └── fabric-ca-client/          # CA client pod deployment
├── scripts/                       # Management and deployment scripts
│   ├── create-ca-secrets.sh       # Kubernetes secret creation
│   ├── enroll-admin.sh            # Admin enrollment
│   ├── register-identities.sh     # Identity registration
│   ├── enroll-ica.sh              # Intermediate CA enrollment
│   ├── backup-ca.sh               # CA backup script
│   └── restore-ca.sh              # CA restoration script
├── fabric-ca/                     # CA server configurations
│   ├── root-ca/
│   ├── cbo-ca/
│   ├── investor-ca/
│   ├── verifier-ca/
│   └── greenstand-ca/
└── README.md                      # This documentation
```

## Certificate Authority Hierarchy

```
Root CA (root-ca)
├── CBO-CA (cbo-ca)                # CBO organization certificates
├── Investor-CA (investor-ca)      # Investor organization certificates  
├── Verifier-CA (verifier-ca)      # Verifier organization certificates
└── Greenstand-CA (greenstand-ca)  # Greenstand organization certificates
```

## Quick Start

### 1. Deploy Root CA
```bash
cd helm-charts/root-ca
helm install root-ca . -n hlf-ca --create-namespace
```

### 2. Deploy CA Client
```bash
cd helm-charts/fabric-ca-client
kubectl apply -f fabric-ca-client.yaml
```

### 3. Enroll Admin
```bash
cd scripts
./enroll-admin.sh
```

### 4. Register Intermediate CAs
```bash
./register-identities.sh
```

### 5. Deploy Intermediate CAs
```bash
cd ../helm-charts/cbo-ca
helm install cbo-ca . -n hlf-ca

cd ../investor-ca  
helm install investor-ca . -n hlf-ca

cd ../verifier-ca
helm install verifier-ca . -n hlf-ca
```

### 6. Enroll Intermediate CAs
```bash
cd ../../scripts
./enroll-ica.sh
```

### 7. Create Kubernetes Secrets
```bash
./create-ca-secrets.sh
```

## Configuration

### Root CA Configuration
- **Image**: hyperledger/fabric-ca:1.5.12
- **Port**: 7054
- **Storage**: 2Gi persistent volume
- **TLS**: Enabled with custom certificates
- **Database**: SQLite3 (configurable to PostgreSQL/MySQL)

### Intermediate CA Configuration
- **Parent**: Root CA
- **Organizations**: CBO, Investor, Verifier, Greenstand
- **Auto-enrollment**: Configured for MSP and TLS certificates
- **Storage**: 2Gi per CA instance

## Management Scripts

### Identity Management
```bash
# Enroll admin identity
./enroll-admin.sh

# Register new intermediate CA
./register-identities.sh

# Enroll intermediate CAs
./enroll-ica.sh
```

### Secret Management
```bash
# Create all CA secrets
./create-ca-secrets.sh

# Backup CA data
./backup-ca.sh

# Restore CA data
./restore-ca.sh
```

## Helm Charts

### Root CA Chart
- **Location**: `helm-charts/root-ca/`
- **Purpose**: Deploys Root Certificate Authority
- **Features**: TLS-enabled, persistent storage, custom CSR configuration

### Intermediate CA Charts
- **Locations**: `helm-charts/{org}-ca/`
- **Purpose**: Deploy organization-specific CAs
- **Features**: Parent CA integration, automatic enrollment, TLS configuration

### CA Client Chart
- **Location**: `helm-charts/fabric-ca-client/`
- **Purpose**: Provides fabric-ca-client for enrollment operations
- **Features**: Persistent client data, configuration management

## Operations

### Daily Operations
```bash
# Check CA pod status
kubectl get pods -n hlf-ca

# View CA logs
kubectl logs -n hlf-ca -l app=root-ca

# Check certificate expiry
kubectl exec -n hlf-ca fabric-ca-client-0 -- \
  fabric-ca-client certificate list --tls.certfiles /data/hyperledger/fabric-ca-client/root-ca/tls-cert.pem
```

### Backup Operations
```bash
# Create backup
./scripts/backup-ca.sh

# Verify backup contents
tar -tzf fabric-ca-backup-*.tgz | head -20

# Store backup securely (off-cluster)
```

### Certificate Renewal
```bash
# Check certificate expiry
for ca in root-ca cbo-ca investor-ca verifier-ca; do
  echo "Checking $ca certificate expiry..."
  kubectl exec -n hlf-ca $ca-0 -- \
    openssl x509 -in /etc/hyperledger/fabric-ca-server/ca-cert.pem -noout -enddate
done

# Renew certificates (if needed)
# Follow certificate renewal runbook
```

## Security Considerations

### Access Control
- **RBAC**: Kubernetes RBAC limits CA access
- **Network policies**: Restrict CA network access
- **Secrets**: TLS certificates stored as Kubernetes secrets
- **Encryption**: All CA communications use TLS

### Certificate Management
- **Root CA**: Highest security - air-gapped if possible
- **Intermediate CAs**: Organization-isolated
- **Key protection**: Private keys stored securely in persistent volumes
- **Certificate rotation**: Regular certificate renewal procedures

## Troubleshooting

### Common Issues

#### CA Pod Not Starting
```bash
# Check pod status and events
kubectl describe pod -n hlf-ca root-ca-0

# Check persistent volume claims
kubectl get pvc -n hlf-ca

# Verify TLS certificates
kubectl get secret -n hlf-ca | grep tls
```

#### Enrollment Failures
```bash
# Check CA client connectivity
kubectl exec -n hlf-ca fabric-ca-client-0 -- \
  fabric-ca-client getcainfo -u https://root-ca.hlf-ca.svc.cluster.local:7054

# Verify TLS certificate
kubectl exec -n hlf-ca fabric-ca-client-0 -- \
  ls -la /data/hyperledger/fabric-ca-client/root-ca/
```

#### Certificate Issues
```bash
# Validate certificate chain
kubectl exec -n hlf-ca fabric-ca-client-0 -- \
  openssl verify -CAfile /data/hyperledger/fabric-ca-client/root-ca/msp/cacerts/root-ca-hlf-ca-svc-cluster-local-7054.pem \
  /data/hyperledger/fabric-ca-client/cbo-ca/msp/signcerts/cert.pem
```

## Integration

### With Peer Networks
- CAs provide certificates for peer MSP and TLS
- Certificate secrets automatically created for peer deployments
- Integration with certificate monitoring system

### With Certificate Monitoring
- CA certificates monitored for expiry
- Automated alerts for CA certificate issues
- Health metrics exported to Prometheus

### With CI/CD Pipeline
- CA validation in deployment pipeline
- Automated certificate checks
- Integration with Jenkins/GitHub Actions

## Maintenance

### Regular Tasks
- **Weekly**: Check CA pod health and logs
- **Monthly**: Review certificate expiry dates
- **Quarterly**: Perform CA backup
- **Annually**: Plan certificate renewal cycle

### Emergency Procedures
- **CA failure**: Restore from backup using restore-ca.sh
- **Certificate expiry**: Emergency certificate renewal
- **Security breach**: Revoke compromised certificates

This CA infrastructure provides a robust foundation for certificate management in your Hyperledger Fabric network with comprehensive automation, monitoring, and operational procedures.
