#!/bin/bash

# Enroll Intermediate CA identities (MSP + TLS)
set -e

NAMESPACE="hlf-ca"
ROOT_CA_URL="https://root-ca.hlf-ca.svc.cluster.local:7054"
TLS_CERT_PATH="/data/hyperledger/fabric-ca-client/root-ca/tls-cert.pem"

# ICA identities and passwords
declare -A ICAS=(
  ["greenstand-ca"]="greenstandcapw"
  ["cbo-ca"]="cbocapw"
  ["investor-ca"]="investorcapw"
  ["verifier-ca"]="verifiercapw"
)

echo "🔐 Enrolling Intermediate CAs (MSP + TLS)..."

for ICA in "${!ICAS[@]}"; do
  PASSWORD="${ICAS[$ICA]}"
  ICA_DIR="/root/hyperledger-fabric-network/${ICA}"

  echo "➡️ Enrolling MSP for $ICA..."
  kubectl exec -n $NAMESPACE fabric-ca-client-0 -- \
    fabric-ca-client enroll \
      --url https://$ICA:$PASSWORD@root-ca.hlf-ca.svc.cluster.local:7054 \
      --tls.certfiles $TLS_CERT_PATH \
      --mspdir $ICA_DIR/msp

  echo "➡️ Enrolling TLS for $ICA..."
  kubectl exec -n $NAMESPACE fabric-ca-client-0 -- \
    fabric-ca-client enroll \
      --url https://$ICA:$PASSWORD@root-ca.hlf-ca.svc.cluster.local:7054 \
      --tls.certfiles $TLS_CERT_PATH \
      --enrollment.profile tls \
      --mspdir $ICA_DIR/tls

  echo "✅ Enrolled $ICA (MSP + TLS)"
done

echo "🎉 All Intermediate CAs enrolled successfully."

