#!/bin/bash

# Create Kubernetes secrets for ICA MSP and TLS
set -e

NAMESPACE="hlf-ca"
ICAS=("greenstand-ca" "cbo-ca" "investor-ca" "verifier-ca")
BASE_PATH="/root/hyperledger-fabric-network"

echo "🔐 Creating Kubernetes secrets for each Intermediate CA..."

for ICA in "${ICAS[@]}"; do
  ICA_DIR="${BASE_PATH}/${ICA}"

  MSP_DIR="${ICA_DIR}/msp"
  TLS_DIR="${ICA_DIR}/tls"

  echo "📦 Creating secrets for $ICA..."

  TLS_CA=$(find ${TLS_DIR}/tlscacerts -name "*.pem" 2>/dev/null)
  TLS_CERT="${TLS_DIR}/signcerts/cert.pem"
  TLS_KEY=$(find ${TLS_DIR}/keystore -name "*.pem" | head -n 1)

  if [[ -f "$TLS_CA" && -f "$TLS_CERT" && -f "$TLS_KEY" ]]; then
    kubectl create secret generic ${ICA}-tls-cert \
      --from-file=ca.crt=$TLS_CA \
      --from-file=server.crt=$TLS_CERT \
      --from-file=server.key=$TLS_KEY \
      -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ TLS secret created for $ICA"
  else
    echo "⚠️ Skipping TLS secret for $ICA — missing files"
  fi

  # MSP Secret
  if [[ -d "$MSP_DIR" ]]; then
    kubectl create secret generic ${ICA}-msp-cert \
      --from-file=signcerts=${MSP_DIR}/signcerts \
      --from-file=keystore=${MSP_DIR}/keystore \
      --from-file=cacerts=${MSP_DIR}/cacerts \
      --from-file=config.yaml=${MSP_DIR}/config.yaml \
      -n ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    echo "✅ MSP secret created for $ICA"
  else
    echo "⚠️ Skipping MSP secret for $ICA — missing directory"
  fi
done

echo "🎉 All ICA secrets created and applied."

