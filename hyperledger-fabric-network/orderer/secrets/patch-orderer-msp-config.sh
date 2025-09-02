#!/usr/bin/env bash
# patch-orderer-msp-config.sh
# Ensure NodeOUs config.yaml is present in orderer0..4 MSP secrets

set -euo pipefail

TARGET_NS="hlf-orderer"
LOCAL_BASE="./_secrets/orderers"

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

ensure_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  printf "%s\n" "$CONFIG_YAML" > "$path"
}

for i in 0 1 2 3 4; do
  ORDERER="orderer${i}"
  MSP_DIR="${LOCAL_BASE}/${ORDERER}/msp"
  CACERTS_DIR="${MSP_DIR}/cacerts"
  SIGNCERTS_DIR="${MSP_DIR}/signcerts"
  KEYSTORE_DIR="${MSP_DIR}/keystore"
  CFG_FILE="${MSP_DIR}/config.yaml"

  echo "==> ${ORDERER}"

  # Basic existence checks (these came from your earlier pull step)
  [[ -d "${CACERTS_DIR}"   ]] || { echo "  ERROR: ${CACERTS_DIR} missing"; exit 1; }
  [[ -d "${SIGNCERTS_DIR}" ]] || { echo "  ERROR: ${SIGNCERTS_DIR} missing"; exit 1; }

  # Always (re)write a fresh config.yaml
  ensure_file "${CFG_FILE}"

  # Build args safely
  ARGS=(
    --namespace "${TARGET_NS}"
    --from-file="${CACERTS_DIR}"
    --from-file="${SIGNCERTS_DIR}"
    --from-file="config.yaml=${CFG_FILE}"
  )
  if [[ -d "${KEYSTORE_DIR}" && -n "$(ls -A "${KEYSTORE_DIR}" 2>/dev/null || true)" ]]; then
    ARGS+=( --from-file="${KEYSTORE_DIR}" )
  fi

  # Apply (create/update) the secret
  kubectl create secret generic "${ORDERER}-msp" "${ARGS[@]}" --dry-run=client -o yaml | kubectl apply -f -

  # Verify config.yaml present
  if kubectl -n "${TARGET_NS}" get secret "${ORDERER}-msp" -o jsonpath='{.data.config\.yaml}' >/dev/null 2>&1; then
    echo "  ✓ config.yaml added to ${ORDERER}-msp"
  else
    echo "  ✗ config.yaml missing on ${ORDERER}-msp (unexpected)"; exit 1
  fi
done

echo "All MSP secrets patched with NodeOUs config.yaml."

