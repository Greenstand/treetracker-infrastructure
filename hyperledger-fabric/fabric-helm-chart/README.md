# TreeTracker Hyperledger Fabric Helm Chart

This Helm chart deploys an enterprise-grade Hyperledger Fabric network tailored for the TreeTracker system. It includes a 5-node RAFT ordering service, multiple organizations (Greenstand, CBO, Investor, Verifier), their respective peers, Certificate Authorities, and GitOps-ready ArgoCD support.

---

## 📦 Components

- **Certificate Authorities** (Root and Intermediate)
- **Ordering Service** with RAFT consensus
- **Peer Nodes** for Greenstand, CBO, Investor, Verifier
- **Channels** and chaincode hooks
- **PVCs, Secrets, ConfigMaps**
- **Ingress for access**
- **ArgoCD Application Manifest** for GitOps

---

## 🚀 Quick Start

### 1. Clone and Navigate

```bash
git clone https://your-repo/fabric-helm-chart.git
cd fabric-helm-chart
```

### 2. Customize `values.yaml`

Edit `values.yaml` to configure:
- TLS certs (`tlsCert`, `tlsKey`, `caCert`)
- Org-specific MSP IDs
- Hostname for ingress

### 3. Install with Helm

```bash
helm install treetracker-network . -n hlf --create-namespace
```

To upgrade later:

```bash
helm upgrade treetracker-network . -n hlf
```

---

## 🛠 GitOps with ArgoCD

### 1. Push this chart to Git

```bash
git init
git remote add origin https://your-git-repo/fabric-helm-chart.git
git add .
git commit -m "Initial commit"
git push -u origin main
```

### 2. Apply ArgoCD Application

```bash
kubectl apply -f templates/argocd-app.yaml
```

This will let ArgoCD continuously deploy and manage the Fabric network via GitOps.

---

## 📂 Namespaces Used

- `hlf-ca` for Certificate Authority
- `hlf-orderer` for Ordering Service
- `greenstand`, `cbo`, `investor`, `verifier` for organization peers

---

## 📄 File Structure

```
fabric-helm-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│   ├── ca.yaml
│   ├── orderer.yaml
│   ├── peer.yaml
│   ├── peer-cbo.yaml
│   ├── peer-investor.yaml
│   ├── peer-verifier.yaml
│   ├── pvc.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── ingress.yaml
│   ├── argocd-app.yaml
```

---

## ✅ Notes

- Make sure base64 values in `values.yaml` are valid and match generated certs.
- Channel creation and chaincode lifecycle should be triggered separately via `fabric-tools` or `kubectl jobs`.

---

## 📬 Support

For help, contact the TreeTracker DevOps team or open a Git issue in your project repo.