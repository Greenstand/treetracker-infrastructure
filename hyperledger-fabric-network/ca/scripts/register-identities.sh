#!/bin/bash

# Register Intermediate CA identities with Root CA
set -e

# Root CA configuration
CA_NAME="root-ca"
NAMESPACE="hlf-ca"
FABRIC_CA_CLIENT_HOME=/data/hyperledger/fabric-ca-client/root-ca
TLS_CERT_PATH=$FABRIC_CA_CLIENT_HOME/tls-cert.pem
CA_HOST="root-ca.hlf-ca.svc.cluster.local:7054"

# Export environment
export FABRIC_CA_CLIENT_HOME=$FABRIC_CA_CLIENT_HOME

# ICA identities to register
declare -A ICAS=(
  ["greenstand-ca"]="greenstandcapw"
  ["cbo-ca"]="cbocapw"
  ["investor-ca"]="investorcapw"
  ["verifier-ca"]="verifiercapw"
)

echo "🔐 Registering Intermediate CAs with Root CA..."

for ICA in "${!ICAS[@]}"; do
  PASSWORD="${ICAS[$ICA]}"

  echo "➡️ Registering $ICA with password '$PASSWORD'..."
  kubectl exec -n $NAMESPACE fabric-ca-client-0 -- \
    fabric-ca-client register \
      --id.name "$ICA" \
      --id.secret "$PASSWORD" \
      --id.type client \
      --id.attrs "hf.IntermediateCA=true" \
      --tls.certfiles "$TLS_CERT_PATH" \
      --url "https://$CA_HOST"

  echo "✅ Registered $ICA"
done

echo "🎉 All Intermediate CAs registered successfully."

