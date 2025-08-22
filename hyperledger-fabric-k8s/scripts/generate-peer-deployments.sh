#!/bin/bash

# Organizations configuration
declare -A orgs=(
    ["greenstand"]="Greenstand"
    ["cbo"]="CBO"
    ["investor"]="Investor"
    ["verifier"]="Verifier"
)

declare -A peer_counts=(
    ["greenstand"]=3
    ["cbo"]=2
    ["investor"]=2
    ["verifier"]=1
)

declare -A msp_ids=(
    ["greenstand"]="GreenstandMSP"
    ["cbo"]="CBOMSP"
    ["investor"]="InvestorMSP"
    ["verifier"]="VerifierMSP"
)

for org in "${!orgs[@]}"; do
    org_name="${orgs[$org]}"
    peer_count=${peer_counts[$org]}
    msp_id=${msp_ids[$org]}
    
    for ((i=0; i<peer_count; i++)); do
        # Determine if this is an anchor peer (peer0 is anchor for each org)
        anchor_peer=""
        if [ $i -eq 0 ]; then
            anchor_peer="true"
        else
            anchor_peer="false"
        fi
        
        cat > "/root/hyperledger-fabric-k8s/peers/peer${i}-${org}.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: peer${i}-${org}
  namespace: hyperledger-fabric
  labels:
    app: peer${i}-${org}
    org: ${org}
    component: peer
    anchor: "${anchor_peer}"
spec:
  replicas: 1
  selector:
    matchLabels:
      app: peer${i}-${org}
  template:
    metadata:
      labels:
        app: peer${i}-${org}
        org: ${org}
        component: peer
        anchor: "${anchor_peer}"
    spec:
      serviceAccountName: fabric-service-account
      containers:
      - name: peer
        image: hyperledger/fabric-peer:2.5.4
        ports:
        - containerPort: 7051
          name: peer-port
        - containerPort: 7052
          name: peer-chaincode
        - containerPort: 9443
          name: operations
        - containerPort: 9444
          name: metrics
        env:
        - name: CORE_VM_ENDPOINT
          value: "unix:///host/var/run/docker.sock"
        - name: CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE
          value: "hyperledger-fabric"
        - name: FABRIC_LOGGING_SPEC
          value: "INFO"
        - name: CORE_PEER_TLS_ENABLED
          value: "true"
        - name: CORE_PEER_GOSSIP_USELEADERELECTION
          value: "true"
        - name: CORE_PEER_GOSSIP_ORGLEADER
          value: "false"
        - name: CORE_PEER_PROFILE_ENABLED
          value: "true"
        - name: CORE_PEER_TLS_CERT_FILE
          value: "/etc/hyperledger/fabric/tls/server.crt"
        - name: CORE_PEER_TLS_KEY_FILE
          value: "/etc/hyperledger/fabric/tls/server.key"
        - name: CORE_PEER_TLS_ROOTCERT_FILE
          value: "/etc/hyperledger/fabric/tls/ca.crt"
        - name: CORE_PEER_ID
          value: "peer${i}.${org}.fabric.local"
        - name: CORE_PEER_ADDRESS
          value: "peer${i}-${org}-service.hyperledger-fabric.svc.cluster.local:7051"
        - name: CORE_PEER_LISTENADDRESS
          value: "0.0.0.0:7051"
        - name: CORE_PEER_CHAINCODEADDRESS
          value: "peer${i}-${org}-service.hyperledger-fabric.svc.cluster.local:7052"
        - name: CORE_PEER_CHAINCODELISTENADDRESS
          value: "0.0.0.0:7052"
        - name: CORE_PEER_GOSSIP_BOOTSTRAP
          value: "peer0-${org}-service.hyperledger-fabric.svc.cluster.local:7051"
        - name: CORE_PEER_GOSSIP_EXTERNALENDPOINT
          value: "peer${i}-${org}-service.hyperledger-fabric.svc.cluster.local:7051"
        - name: CORE_PEER_LOCALMSPID
          value: "${msp_id}"
        - name: CORE_PEER_MSPCONFIGPATH
          value: "/etc/hyperledger/fabric/msp"
        - name: CORE_OPERATIONS_LISTENADDRESS
          value: "0.0.0.0:9443"
        - name: CORE_METRICS_PROVIDER
          value: "prometheus"
        - name: CORE_PEER_TLS_SERVERHOSTOVERRIDE
          value: "peer${i}.${org}.fabric.local"
        - name: CORE_LEDGER_STATE_STATEDATABASE
          value: "CouchDB"
        - name: CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS
          value: "couchdb-peer${i}-${org}:5984"
        - name: CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME
          value: "couchdb"
        - name: CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD
          value: "couchdb"
        command: ["peer"]
        args: ["node", "start"]
        volumeMounts:
        - name: peer-data
          mountPath: /var/hyperledger/production
        - name: peer-msp
          mountPath: /etc/hyperledger/fabric/msp
        - name: peer-tls
          mountPath: /etc/hyperledger/fabric/tls
        - name: docker-sock
          mountPath: /host/var/run/docker.sock
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
      - name: couchdb
        image: couchdb:3.3
        ports:
        - containerPort: 5984
          name: couchdb-port
        env:
        - name: COUCHDB_USER
          value: "couchdb"
        - name: COUCHDB_PASSWORD
          value: "couchdb"
        volumeMounts:
        - name: couchdb-data
          mountPath: /opt/couchdb/data
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: peer-data
        persistentVolumeClaim:
          claimName: peer${i}-${org}-data-pvc
      - name: couchdb-data
        persistentVolumeClaim:
          claimName: peer${i}-${org}-couchdb-pvc
      - name: peer-msp
        configMap:
          name: peer${i}-${org}-msp-config
      - name: peer-tls
        configMap:
          name: peer${i}-${org}-tls-config
      - name: docker-sock
        hostPath:
          path: /var/run/docker.sock
---
apiVersion: v1
kind: Service
metadata:
  name: peer${i}-${org}-service
  namespace: hyperledger-fabric
  labels:
    app: peer${i}-${org}
    org: ${org}
    anchor: "${anchor_peer}"
spec:
  selector:
    app: peer${i}-${org}
  ports:
  - name: peer-port
    port: 7051
    targetPort: 7051
  - name: peer-chaincode
    port: 7052
    targetPort: 7052
  - name: operations
    port: 9443
    targetPort: 9443
  - name: metrics
    port: 9444
    targetPort: 9444
  type: ClusterIP
---
apiVersion: v1
kind: Service
metadata:
  name: couchdb-peer${i}-${org}
  namespace: hyperledger-fabric
  labels:
    app: peer${i}-${org}
    component: couchdb
spec:
  selector:
    app: peer${i}-${org}
  ports:
  - name: couchdb-port
    port: 5984
    targetPort: 5984
  type: ClusterIP
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: peer${i}-${org}-data-pvc
  namespace: hyperledger-fabric
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fabric-storage
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: peer${i}-${org}-couchdb-pvc
  namespace: hyperledger-fabric
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: fabric-storage
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: peer${i}-${org}-msp-config
  namespace: hyperledger-fabric
data:
  # Placeholder - these should be replaced with actual certificates
  admincerts.pem: |
    -----BEGIN CERTIFICATE-----
    # ${org_name} Admin Certificate
    -----END CERTIFICATE-----
  cacerts.pem: |
    -----BEGIN CERTIFICATE-----
    # ${org_name} CA Certificate
    -----END CERTIFICATE-----
  signcerts.pem: |
    -----BEGIN CERTIFICATE-----
    # Peer${i} ${org_name} Signing Certificate
    -----END CERTIFICATE-----
  keystore.key: |
    -----BEGIN PRIVATE KEY-----
    # Peer${i} ${org_name} Private Key
    -----END PRIVATE KEY-----
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: peer${i}-${org}-tls-config
  namespace: hyperledger-fabric
data:
  # Placeholder - these should be replaced with actual TLS certificates
  server.crt: |
    -----BEGIN CERTIFICATE-----
    # Peer${i} ${org_name} TLS Server Certificate
    -----END CERTIFICATE-----
  server.key: |
    -----BEGIN PRIVATE KEY-----
    # Peer${i} ${org_name} TLS Server Private Key
    -----END PRIVATE KEY-----
  ca.crt: |
    -----BEGIN CERTIFICATE-----
    # ${org_name} TLS CA Certificate
    -----END CERTIFICATE-----
EOF
    
    echo "Generated peer${i} configuration for ${org}"
    done
    
    echo "Completed all peers for ${org}"
done

echo "All peer deployments generated successfully!"
