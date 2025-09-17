<img width="1291" height="812" alt="Treetracker HLF Network" src="https://github.com/user-attachments/assets/0d799dd3-5c09-402b-8f33-ed6c2b61df25" />

<div align="center">
  <h3>🌳 Blockchain-based Tree Tracking Network 🌳</h3>
  <p>A production-ready Hyperledger Fabric network for transparent tree planting and carbon offset tracking</p>
</div>

[![Hyperledger Fabric](https://img.shields.io/badge/Hyperledger%20Fabric-2.5.7-blue.svg)](https://hyperledger-fabric.readthedocs.io/)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28+-blue.svg)](https://kubernetes.io/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)
[![Network Status](https://img.shields.io/badge/Network-Production%20Ready-brightgreen.svg)](#)

---

## 🌍 Overview

The Hyperledger Fabric Treetracker Network is a blockchain-based solution designed to provide transparent, immutable tracking of tree planting initiatives and carbon offset programs. Built for [Greenstand](https://greenstand.org/) and partners, this network ensures accountability in environmental restoration projects through distributed ledger technology.

### Key Features

- **🔒 Immutable Tree Records** - Every tree planting event is permanently recorded on the blockchain
- **🤝 Multi-Organization Network** - Supports Greenstand, CBOs, Investors, and Verifiers
- **🌐 Public Transparency** - All stakeholders can verify tree planting data
- **📊 Real-time Analytics** - Live dashboards for monitoring forest restoration progress
- **🔐 Enterprise Security** - Certificate-based authentication and TLS encryption
- **📈 Scalable Infrastructure** - Kubernetes-based deployment supporting global operations

---

## 🏗️ Network Architecture

### Organizations

| Organization | Role | Peers | Description |
|--------------|------|-------|-------------|
| **Greenstand** | Network Admin | 3 | Primary tree tracking organization |
| **CBO** | Tree Planters | 2 | Community-Based Organizations |
| **Investor** | Funders | 2 | Carbon offset purchasers |
| **Verifier** | Validators | 1 | Independent verification entities |

### Network Components

- **🏦 Ordering Service**: 5-node Raft consensus cluster
- **🔐 Certificate Authorities**: 5 CAs (1 Root + 4 Organization CAs)
- **📊 Monitoring**: Prometheus + Grafana stack
- **🗄️ Storage**: Persistent volumes with automatic backup
- **🌐 API Gateway**: RESTful APIs for external integration

---

## 🚀 Quick Start

### Prerequisites

- **Kubernetes Cluster**: v1.23+ with 5+ nodes
- **Storage**: 500GB+ SSD with dynamic provisioning
- **Resources**: 32+ CPU cores, 64GB+ RAM
- **Network**: LoadBalancer support for external access

### 1. Clone the Repository

```bash
git clone https://github.com/Greenstand/hyperledger-fabric-network.git
cd hyperledger-fabric-network
```

### 2. Deploy the Network

```bash
# Deploy complete network infrastructure
./scripts/deploy-treetracker-network.sh

# Create channels
./scripts/create-channels.sh

# Deploy chaincode
./scripts/deploy-chaincode.sh

# Verify deployment
./scripts/test-network.sh
```

### 3. Access the Network

```bash
# Get network status
kubectl get pods --all-namespaces | grep hlf-

# Access API Gateway
kubectl port-forward svc/api-gateway 8080:80 -n treetracker-apps

# View monitoring dashboard
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

---

## 📚 Documentation

Comprehensive documentation is available in the `/docs` directory:

### For Users & Operators
- 📖 **[User Manual](docs/TREETRACKER_USER_MANUAL.md)** - Complete user guide for network operations
- 🛠️ **[Deployment Guide](docs/TREETRACKER_DEPLOYMENT_GUIDE.md)** - Step-by-step deployment instructions

### For Developers
- 💻 **[Integration Manual](docs/TREETRACKER_INTEGRATION_MANUAL.md)** - SDK usage and API integration
- 🏗️ **[Architecture Guide](docs/TREETRACKER_ARCHITECTURE_GUIDE.md)** - Network design and component details

### Quick Reference
- [API Documentation](docs/TREETRACKER_INTEGRATION_MANUAL.md#api-reference)
- [Chaincode Functions](docs/TREETRACKER_INTEGRATION_MANUAL.md#chaincode-development)
- [Troubleshooting Guide](docs/TREETRACKER_DEPLOYMENT_GUIDE.md#troubleshooting)
- [Monitoring & Alerts](docs/TREETRACKER_ARCHITECTURE_GUIDE.md#monitoring-and-observability)

---

## 🌐 Network Endpoints

### Production Network
- **API Gateway**: `https://api.treetracker.network`
- **Blockchain Explorer**: `https://explorer.treetracker.network`
- **Monitoring Dashboard**: `https://monitoring.treetracker.network`

### Development Network
- **API Gateway**: `http://localhost:8080`
- **Grafana**: `http://localhost:3000`
- **Prometheus**: `http://localhost:9090`

---

## 🔧 Directory Structure

```
hyperledger-fabric-network/
├── 📁 chaincode/              # Smart contracts
│   └── treetracker/           # Tree tracking chaincode (Go)
├── 📁 config/                 # Network configuration
│   ├── configtx.yaml         # Channel configuration
│   ├── crypto-config.yaml    # Certificate configuration
│   └── network-config.yaml   # Main network settings
├── 📁 docs/                   # Documentation
│   ├── TREETRACKER_USER_MANUAL.md
│   ├── TREETRACKER_INTEGRATION_MANUAL.md
│   ├── TREETRACKER_ARCHITECTURE_GUIDE.md
│   └── TREETRACKER_DEPLOYMENT_GUIDE.md
├── 📁 k8s/                    # Kubernetes manifests
│   ├── ca/                   # Certificate Authority deployments
│   ├── orderer/              # Orderer node deployments
│   ├── peers/                # Peer node deployments
│   └── monitoring/           # Monitoring stack
├── 📁 scripts/               # Deployment and management scripts
│   ├── deploy-treetracker-network.sh
│   ├── create-channels.sh
│   ├── deploy-chaincode.sh
│   └── test-network.sh
└── 📁 api/                   # REST API gateway
    ├── nodejs/               # Node.js SDK integration
    └── gateway/              # API Gateway service
```

---

## 🔐 Security Features

### Certificate Management
- **Root CA**: Self-signed root certificate authority
- **Organization CAs**: Individual CAs for each organization
- **TLS Encryption**: All network communication encrypted
- **Certificate Rotation**: Automated certificate lifecycle management

### Network Security
- **RBAC**: Role-based access control for all operations
- **Network Policies**: Kubernetes network segmentation
- **Mutual TLS**: Peer-to-peer authentication
- **HSM Support**: Hardware security module integration (optional)

### Data Privacy
- **Channel Isolation**: Private data channels between organizations
- **Endorsement Policies**: Multi-signature transaction validation
- **Audit Trails**: Immutable transaction logs
- **Data Encryption**: At-rest and in-transit encryption

---

## 📊 Monitoring & Observability

### Metrics Collection
- **Peer Metrics**: Transaction throughput, ledger size, endorsement latency
- **Orderer Metrics**: Block creation rate, consensus performance
- **Network Metrics**: Channel health, certificate status
- **Application Metrics**: API response times, chaincode execution

### Alerting
- **Network Health**: Peer/orderer downtime alerts
- **Performance**: Transaction latency thresholds
- **Security**: Certificate expiration warnings
- **Capacity**: Storage and resource utilization

### Dashboards
- **Executive Dashboard**: High-level KPIs and network status
- **Operations Dashboard**: Detailed technical metrics
- **Business Dashboard**: Tree planting progress and carbon metrics

---

## 🧪 Testing & Quality Assurance

### Test Coverage
- **Unit Tests**: Chaincode function testing
- **Integration Tests**: End-to-end network testing
- **Performance Tests**: Load testing and benchmarking
- **Security Tests**: Penetration testing and vulnerability scans

### Continuous Integration
- **Automated Testing**: GitHub Actions CI/CD pipeline
- **Code Quality**: SonarQube analysis
- **Security Scanning**: Container and dependency scanning
- **Deployment Testing**: Automated deployment validation

---

## 🚀 Deployment Options

### Cloud Providers
- **AWS**: EKS with managed services
- **Google Cloud**: GKE with Cloud SQL
- **Azure**: AKS with Azure Storage
- **DigitalOcean**: DOKS with block storage

### On-Premises
- **Bare Metal**: Direct Kubernetes installation
- **VMware**: vSphere with Tanzu
- **OpenShift**: Red Hat OpenShift platform

### Development
- **Kind**: Local Kubernetes in Docker
- **Minikube**: Single-node local cluster
- **Docker Compose**: Simplified local development

---

## 🤝 Contributing

We welcome contributions from the community! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request

### Code Standards
- **Go**: Follow Go best practices for chaincode
- **JavaScript**: ESLint configuration for API code
- **Documentation**: Update docs for any API changes
- **Testing**: Maintain 80%+ test coverage

---

## 📞 Support & Community

### Getting Help
- **Documentation**: Comprehensive guides in `/docs`
- **GitHub Issues**: Bug reports and feature requests
- **Discord**: Real-time community support
- **Email**: technical-support@greenstand.org

### Community Resources
- **Greenstand Website**: [https://greenstand.org](https://greenstand.org)
- **Slack Channel**: [#treetracker-blockchain](https://greenstand.slack.com)
- **Developer Forum**: [https://forum.greenstand.org](https://forum.greenstand.org)

---

## 📈 Roadmap

### Current Release (v1.0)
- ✅ Multi-organization network
- ✅ Tree tracking chaincode
- ✅ Kubernetes deployment
- ✅ Monitoring and alerting

### Next Release (v1.1)
- 🔄 Mobile wallet integration
- 🔄 Carbon credit tokenization
- 🔄 Enhanced analytics dashboard
- 🔄 Multi-chain interoperability

### Future Releases
- 📋 IoT sensor integration
- 📋 Satellite imagery verification
- 📋 Machine learning analytics
- 📋 Cross-border payment rails

---

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Hyperledger Foundation**: For the excellent Fabric framework
- **Greenstand Team**: For environmental vision and leadership
- **Open Source Community**: For tools, libraries, and inspiration
- **Tree Planting Partners**: CBOs worldwide making real impact

---

**🌱 Together, we're growing a more transparent and sustainable future through blockchain technology! 🌱**

<div align="center">
  <strong>Architected with ❤️ by <a href="https://github.com/imos64">Imos Aikoroje</a>  For Greenstand Community</strong><br>
  <a href="https://greenstand.org">greenstand.org</a> | 
  <a href="https://github.com/Greenstand">GitHub</a> 
</div>
