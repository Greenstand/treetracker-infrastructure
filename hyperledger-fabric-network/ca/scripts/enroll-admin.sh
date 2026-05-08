#!/bin/bash

# Root CA Enroll Admin Script

set -e

# Configuration
CA_NAME="root-ca"
NAMESPACE="hlf-ca"
FABRIC_CA_CLIENT_HOME=/data/hyperledger/fabric-ca-client/root-ca
TLS_CERT_PATH=$FABRIC_CA_CLIENT_HOME/tls-cert.pem
CA_HOST="root-ca.hlf-ca.svc.cluster.local:7054"
ADMIN_USER="admin"
ADMIN_PASS="adminpw"

echo "📂 Setting FABRIC_CA_CLIENT_HOME=$FABRIC_CA_CLIENT_HOME"
export FABRIC_CA_CLIENT_HOME=$FABRIC_CA_CLIENT_HOME

echo "📥 Creating directories..."
mkdir -p $FABRIC_CA_CLIENT_HOME

echo "🔍 Fetching Root CA pod name..."
ROOT_CA_POD=$(kubectl get pods -n $NAMESPACE -l app=$CA_NAME -o jsonpath="{.items[0].metadata.name}")
echo "📦 Found pod: $ROOT_CA_POD"

echo "📦 Copying TLS cert from pod to local..."
kubectl cp $NAMESPACE/$ROOT_CA_POD:/etc/hyperledger/fabric-ca-server/ca-cert.pem ./tls-cert.pem

echo "📦 Copying TLS cert to fabric-ca-client pod..."
kubectl cp ./tls-cert.pem $NAMESPACE/fabric-ca-client-0:$TLS_CERT_PATH

echo "🔐 Enrolling admin..."
kubectl exec -n $NAMESPACE fabric-ca-client-0 -- \
  fabric-ca-client enroll \
    --url https://$ADMIN_USER:$ADMIN_PASS@$CA_HOST \
    --tls.certfiles $TLS_CERT_PATH

echo "✅ Root CA Admin enrolled successfully."

