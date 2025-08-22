#!/bin/bash

# Organizations configuration
declare -A orgs=(
    ["cbo"]="CBO Organization"
    ["investor"]="Investor Organization"  
    ["verifier"]="Verifier Organization"
)

declare -A peer_counts=(
    ["cbo"]=2
    ["investor"]=2
    ["verifier"]=1
)

declare -A locations=(
    ["cbo"]="Kenya|Nairobi"
    ["investor"]="New York|New York"
    ["verifier"]="Geneva|Geneva"
)

for org in "${!orgs[@]}"; do
    org_name="${orgs[$org]}"
    peer_count=${peer_counts[$org]}
    IFS='|' read -r state city <<< "${locations[$org]}"
    
    # Generate peer identities
    peer_identities=""
    for ((i=0; i<peer_count; i++)); do
        peer_identities+="""        - name: peer${i}-${org}
          pass: peer${i}pw
          type: peer
          affiliation: \"${org}\"
          attrs:
            hf.Registrar.Roles: \"peer\"
"""
    done

    cat > "/root/hyperledger-fabric-k8s/ca/${org}-ca.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fabric-ca-${org}
  namespace: hyperledger-fabric
  labels:
    app: fabric-ca-${org}
    org: ${org}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fabric-ca-${org}
  template:
    metadata:
      labels:
        app: fabric-ca-${org}
        org: ${org}
    spec:
      serviceAccountName: fabric-service-account
      containers:
      - name: fabric-ca-server
        image: hyperledger/fabric-ca:1.5.6
        ports:
        - containerPort: 7054
        env:
        - name: FABRIC_CA_HOME
          value: /etc/hyperledger/fabric-ca-server
        - name: FABRIC_CA_SERVER_CA_NAME
          value: ca-${org}
        - name: FABRIC_CA_SERVER_TLS_ENABLED
          value: "true"
        - name: FABRIC_CA_SERVER_PORT
          value: "7054"
        - name: FABRIC_CA_SERVER_OPERATIONS_LISTENADDRESS
          value: "0.0.0.0:17054"
        command: ["sh"]
        args:
        - -c
        - |
          fabric-ca-server init -b admin:adminpw
          fabric-ca-server start --ca.certfile /etc/hyperledger/fabric-ca-server/ca-cert.pem --ca.keyfile /etc/hyperledger/fabric-ca-server/msp/keystore/ca_key.pem -b admin:adminpw -d
        volumeMounts:
        - name: fabric-ca-data
          mountPath: /etc/hyperledger/fabric-ca-server
        - name: fabric-ca-config
          mountPath: /etc/hyperledger/fabric-ca-server/fabric-ca-server-config.yaml
          subPath: fabric-ca-server-config.yaml
      volumes:
      - name: fabric-ca-data
        persistentVolumeClaim:
          claimName: fabric-ca-${org}-pvc
      - name: fabric-ca-config
        configMap:
          name: fabric-ca-${org}-config
---
apiVersion: v1
kind: Service
metadata:
  name: fabric-ca-${org}-service
  namespace: hyperledger-fabric
  labels:
    org: ${org}
spec:
  selector:
    app: fabric-ca-${org}
  ports:
  - name: ca-port
    port: 7054
    targetPort: 7054
  - name: operations
    port: 17054
    targetPort: 17054
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fabric-ca-${org}-pvc
  namespace: hyperledger-fabric
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fabric-storage
  resources:
    requests:
      storage: 2Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fabric-ca-${org}-config
  namespace: hyperledger-fabric
data:
  fabric-ca-server-config.yaml: |
    version: 1.5.6
    port: 7054
    debug: false
    crlsizelimit: 512000
    tls:
      enabled: true
      certfile: /etc/hyperledger/fabric-ca-server/ca-cert.pem
      keyfile: /etc/hyperledger/fabric-ca-server/msp/keystore/ca_key.pem
    ca:
      name: ca-${org}
      keyfile: /etc/hyperledger/fabric-ca-server/msp/keystore/ca_key.pem
      certfile: /etc/hyperledger/fabric-ca-server/ca-cert.pem
      chainfile: /etc/hyperledger/fabric-ca-server/ca-chain.pem
    registry:
      maxenrollments: -1
      identities:
        - name: admin
          pass: adminpw
          type: client
          affiliation: "${org}"
          attrs:
            hf.Registrar.Roles: "*"
            hf.Registrar.DelegateRoles: "*"
            hf.Revoker: true
            hf.GenCRL: true
            hf.Registrar.Attributes: "*"
            hf.AffiliationMgr: true
${peer_identities}    db:
      type: sqlite3
      datasource: fabric-ca-server.db
      tls:
        enabled: false
    affiliations:
      ${org}:
        - admin
        - peer
    signing:
      default:
        usage:
          - digital signature
        expiry: 8760h
      profiles:
        ca:
          usage:
            - cert sign
            - crl sign
          expiry: 43800h
          caconstraint:
            isca: true
            maxpathlenzero: false
        tls:
          usage:
            - signing
            - key encipherment
            - server auth
            - client auth
            - key agreement
          expiry: 8760h
    csr:
      cn: fabric-ca-${org}
      keyrequest:
        algo: ecdsa
        size: 256
      names:
        - C: US
          ST: "${state}"
          L: "${city}"
          O: "${org_name}"
          OU: "Blockchain"
      hosts:
        - fabric-ca-${org}-service
        - localhost
    operations:
      listenAddress: 0.0.0.0:17054
      tls:
        enabled: false
EOF

    echo "Generated CA configuration for ${org}"
done

echo "All organization CAs generated successfully!"
