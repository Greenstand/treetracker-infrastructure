#!/usr/bin/env bash
# add-orderer-msp-config.sh
set -euo pipefail

TARGET_NS="hlf-orderer"
LOCAL_BASE="./_secrets/orderers"

# NodeOUs config (OU-only; no CA file pinning needed since Fabric-CA sets OUs)
read -r -d '' CONFIG_YAML <<'YAML'
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    OrganizationalUnitIdentifier: orderer
YAML

for i in 0 1 2 3 4; do
  ORDERER="orderer${i}"
  MSP_DIR="${LOCAL_BASE}/${ORDERER}/msp"

  if [[ ! -d "${MSP_DIR}/signcerts" || ! -d "${MSP_DIR}/cacerts" ]]; then
    echo "ERROR: Missing MSP dirs for ${ORDERER} in ${MSP_DIR}. Re-run the pull step first."
    exit 1
  fi

  echo "==> Patching ${ORDERER}-msp with config.yaml"
  printf "%s\n" "${CONFIG_YAML}" > "${MSP_DIR}/config.yaml"

  kubectl create secret generic "${ORDERER}-msp" \
    --namespace "${TARGET_NS}" \
    --from-file="${MSP_DIR}/cacerts" \
    --from-file="${MSP_DIR}/signcerts" \
    $( [[ -d "${MSP_DIR}/keystore" && -n "$(ls -A "${MSP_DIR}/keystore" 2>/dev/null || true)" ]] && echo --from-file="${MSP_DIR}/keystore" ) \
    --from-file=config.yaml="${MSP_DIR}/config.yaml" \
    --dry-run=client -o yaml | kubectl apply -f -
done

echo "All MSP secrets patched with NodeOUs config.yaml."

