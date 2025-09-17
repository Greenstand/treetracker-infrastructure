# Kyverno Security Policies for Hyperledger Fabric Orderer

This directory contains Kyverno admission controller policies to enforce security baselines and validation for Hyperledger Fabric orderer workloads.

## Prerequisites

- Kyverno installed in the cluster: `kubectl apply -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml`
- Orderer namespace: `orderer`

## Policy Overview

### 1. disallow-latest-tags.yaml
- **Purpose**: Prevents use of `:latest` image tags
- **Scope**: Pod, Deployment, StatefulSet in orderer namespace
- **Enforcement**: Block resources with latest tags

### 2. enforce-security-context.yaml
- **Purpose**: Enforce security hardening for orderer containers
- **Rules**: 
  - Run as non-root user
  - No privilege escalation
  - RuntimeDefault seccomp profile
  - Drop all Linux capabilities
- **Scope**: All containers in orderer namespace

### 3. validate-orderer-secrets.yaml
- **Purpose**: Validate orderer secret structure
- **Rules**:
  - MSP secret (fabric-orderer-msp) must have: cacerts, signcerts, keystore, config.yaml
  - TLS secret (fabric-orderer-tls) must have: tls.crt, tls.key, ca.crt
- **Scope**: Specific orderer secrets

### 4. validate-genesis-block.yaml
- **Purpose**: Validate Genesis block configuration
- **Rules**:
  - ConfigMap fabric-genesis-block must contain genesis.block data
  - StatefulSet fabric-orderer must mount Genesis block ConfigMap
- **Scope**: Genesis block ConfigMap and orderer StatefulSet

### 5. restrict-network-access.yaml
- **Purpose**: Generate NetworkPolicy for network isolation
- **Rules**: 
  - Allow from peer namespaces (port 7050)
  - Allow inter-orderer Raft communication (port 7050)
  - Allow monitoring access to operations endpoint (port 9443)
- **Type**: Generative policy (creates NetworkPolicy resources)

## Installation

Apply all policies:
```bash
kubectl apply -f policies/kyverno/
```

Or apply individually:
```bash
kubectl apply -f policies/kyverno/disallow-latest-tags.yaml
kubectl apply -f policies/kyverno/enforce-security-context.yaml
kubectl apply -f policies/kyverno/validate-orderer-secrets.yaml
kubectl apply -f policies/kyverno/validate-genesis-block.yaml
kubectl apply -f policies/kyverno/restrict-network-access.yaml
```

## Verification

Check policy status:
```bash
kubectl get cpol
kubectl describe cpol orderer-disallow-latest-tags
```

Test policy violations (should fail):
```bash
# This should be blocked
kubectl -n orderer create deployment test --image=nginx:latest
```

View generated NetworkPolicies:
```bash
kubectl -n orderer get networkpolicy orderer-ingress-policy
```

## Policy Modes

Policies can run in different modes:
- `enforce`: Block non-compliant resources (default)
- `audit`: Allow but log violations

To switch to audit mode:
```yaml
spec:
  validationFailureAction: audit
```

## Customization

### Network Policy Adjustments
Modify `restrict-network-access.yaml`:
- Update peer namespace selectors and labels
- Add/remove allowed ports and sources
- Adjust monitoring namespace references

### Secret Validation
Update `validate-orderer-secrets.yaml`:
- Modify secret names if using different naming convention
- Add additional validation rules for secret content

### Genesis Block Validation
Adjust `validate-genesis-block.yaml`:
- Change ConfigMap name if using different naming
- Modify volume mount requirements

## Monitoring

View policy violations:
```bash
kubectl get events --field-selector reason=PolicyViolation
kubectl get events --field-selector reason=PolicyApplied
```

Use Kyverno policy reports:
```bash
kubectl get polr -A  # Policy Reports
kubectl get cpolr    # Cluster Policy Reports
```

## Troubleshooting

**Policy not enforcing**: 
- Verify Kyverno is running: `kubectl -n kyverno get pods`
- Check policy status: `kubectl get cpol <policy-name> -o yaml`

**NetworkPolicy not generated**:
- Ensure orderer namespace exists
- Check generate policy conditions and labels

**Secret validation failing**:
- Verify secret naming matches policy patterns
- Ensure secrets contain all required keys

**Genesis block validation failing**:
- Confirm ConfigMap name matches policy expectation
- Verify Genesis block data is present

## Network Policy Requirements

For the generated NetworkPolicy to work properly, ensure peer namespaces are labeled:
```bash
kubectl label namespace greenstand peer-access=true
kubectl label namespace cbo peer-access=true
kubectl label namespace investor peer-access=true
kubectl label namespace verifier peer-access=true
```

For monitoring access (optional):
```bash
kubectl label namespace monitoring monitoring-access=true
```

## References

- [Kyverno Documentation](https://kyverno.io/docs/)
- [Kubernetes NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Hyperledger Fabric Security](https://hyperledger-fabric.readthedocs.io/en/latest/security.html)
- [Raft Consensus Security](https://raft.github.io/)
