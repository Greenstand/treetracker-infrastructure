# 🔗 fabric-orderer-helm-chart

A reusable and configurable Helm chart for deploying a **Hyperledger Fabric Ordering Service** using the **etcd/RAFT consensus protocol**. This chart supports deploying multiple orderer nodes as Kubernetes StatefulSets, along with required TLS and MSP secrets, genesis block, and persistent volumes.

---

## 📁 Directory Structure

```bash
fabric-orderer-helm-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── configmap-genesis.yaml     # (Optional) Genesis block as base64 (if not using secret)
│   ├── pvc.yaml                   # PVC for persistent ledger storage
│   ├── secret-msp.yaml            # Orderer MSP secrets
│   ├── secret-tls.yaml            # TLS secrets (server.crt, server.key, ca.crt)
│   ├── service-orderer.yaml       # ClusterIP services for each orderer
│   └── statefulset-orderer.yaml   # Main StatefulSet template for orderers
```

---

## ✅ Prerequisites

- Kubernetes Cluster (v1.20+)
- [Helm](https://helm.sh) v3.6+
- Generated crypto material:
  - TLS certs/keys for each orderer
  - MSP directory structure (admincerts, cacerts, signcerts, keystore)
  - `genesis.block` for system channel
- Kubernetes secrets created from crypto files:
  ```bash
  kubectl create secret generic orderer0-tls --from-file=...
  kubectl create secret generic orderer0-msp --from-file=...
  kubectl create secret generic orderer-genesis-block --from-literal=genesis.block="$(base64 -w 0 genesis.block)"
  ```

---

## 📦 Configuration (values.yaml)

```yaml
namespace: hyperledger-fabric

image:
  repository: hyperledger/fabric-orderer
  tag: 2.5
  pullPolicy: IfNotPresent

persistence:
  size: 2Gi

genesis:
  secretName: orderer-genesis-block
  fileKey: genesis.block

orderer:
  mspID: OrdererMSP
  nodes:
    - name: orderer0
      namespace: hyperledger-fabric
      mspSecret: orderer0-msp
      tlsSecret: orderer0-tls
    - name: orderer1
      namespace: hyperledger-fabric
      mspSecret: orderer1-msp
      tlsSecret: orderer1-tls
    - name: orderer2
      namespace: hyperledger-fabric
      mspSecret: orderer2-msp
      tlsSecret: orderer2-tls
    - name: orderer3
      namespace: hyperledger-fabric
      mspSecret: orderer3-msp
      tlsSecret: orderer3-tls
    - name: orderer4
      namespace: hyperledger-fabric
      mspSecret: orderer4-msp
      tlsSecret: orderer4-tls
```

---

## 🚀 Installation

```bash
# Create the namespace
kubectl create namespace hyperledger-fabric

# Install the chart
helm install fabric-orderers . -n hyperledger-fabric --create-namespace
```

To upgrade with new values:
```bash
helm upgrade fabric-orderers . -n hyperledger-fabric
```

To render for inspection:
```bash
helm template fabric-orderers . -n hyperledger-fabric > rendered-orderers.yaml
```

---

## 🔍 Verifying Deployment

```bash
kubectl get pods -n hyperledger-fabric
kubectl get statefulsets -n hyperledger-fabric
kubectl logs orderer0-0 -n hyperledger-fabric
```

---

## 🛠 Troubleshooting

| Symptom                         | Possible Cause                    | Fix |
|----------------------------------|------------------------------------|-----|
| `CrashLoopBackOff`               | Malformed genesis block           | Verify the base64 content and genesis creation |
| `invalid wire-format` error      | Wrong file encoding or corrupt    | Recreate the secret with valid genesis.block |
