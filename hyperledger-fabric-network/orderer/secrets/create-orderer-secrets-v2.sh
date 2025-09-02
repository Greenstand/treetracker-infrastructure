#!/usr/bin/env bash
# create-orderer-secrets-v2.sh
set -euo pipefail

CA_NS="hlf-ca"
CA_CLIENT_POD="fabric-ca-client-0"
TARGET_NS="hlf-orderer"
LOCAL_BASE="./_secrets/orderers"

kubectl get ns "${TARGET_NS}" >/dev/null 2>&1 || kubectl create ns "${TARGET_NS}"
mkdir -p "${LOCAL_BASE}"

pull_from_pod() {
  local remote="$1" ; local local_path="$2"
  mkdir -p "$(dirname "${local_path}")"
  # Wrap kubectl cp so missing paths don't kill the script when caller says "optional"
  if ! kubectl cp "${CA_NS}/${CA_CLIENT_POD}:${remote}" "${local_path}" 2>&1; then
    return 1
  fi
}

for i in 0 1 2 3 4; do
  ORDERER="orderer${i}"
  echo "==> Processing ${ORDERER}"

  REMOTE_BASE="/data/hyperledger/fabric-ca-client/${ORDERER}"
  LOCAL_DIR="${LOCAL_BASE}/${ORDERER}"
  MSP_DIR="${LOCAL_DIR}/msp"
  TLS_DIR="${LOCAL_DIR}/tls"
  TLS_OUT="${LOCAL_DIR}/tls-ready"
  mkdir -p "${MSP_DIR}" "${TLS_DIR}" "${TLS_OUT}"

  echo "  - Pulling MSP (signcerts, cacerts, keystore?, config.yaml?)"
  pull_from_pod "${REMOTE_BASE}/msp/signcerts" "${MSP_DIR}/signcerts"
  pull_from_pod "${REMOTE_BASE}/msp/cacerts"    "${MSP_DIR}/cacerts"
  pull_from_pod "${REMOTE_BASE}/msp/keystore"   "${MSP_DIR}/keystore" || echo "    (keystore not found yet — ok)"
  pull_from_pod "${REMOTE_BASE}/msp/config.yaml" "${MSP_DIR}/config.yaml" || echo "    (config.yaml not found — ok)"

  echo "  - Pulling TLS (signcerts, keystore?, tlscacerts)"
  pull_from_pod "${REMOTE_BASE}/tls/signcerts"   "${TLS_DIR}/signcerts"
  pull_from_pod "${REMOTE_BASE}/tls/keystore"    "${TLS_DIR}/keystore" || echo "    (tls keystore not found — ok)"
  pull_from_pod "${REMOTE_BASE}/tls/tlscacerts"  "${TLS_DIR}/tlscacerts"

  echo "  - Normalizing TLS filenames"
  SIGNCRT="$(ls -1 ${TLS_DIR}/signcerts/* 2>/dev/null | head -n1 || true)"
  KEYFILE="$(ls -1 ${TLS_DIR}/keystore/* 2>/dev/null | head -n1 || true)"
  CACRT="$(ls -1 ${TLS_DIR}/tlscacerts/* 2>/dev/null | head -n1 || true)"

  if [[ -z "${SIGNCRT}" || -z "${KEYFILE}" || -z "${CACRT}" ]]; then
    echo "    ERROR: Missing TLS files for ${ORDERER}."
    echo "           SIGNCRT='${SIGNCRT}' KEYFILE='${KEYFILE}' CACRT='${CACRT}'"
    echo "           Re-run TLS enroll for ${ORDERER} before creating secrets."
    exit 1
  fi

  cp -f "${SIGNCRT}" "${TLS_OUT}/server.crt"
  cp -f "${KEYFILE}" "${TLS_OUT}/server.key"
  cp -f "${CACRT}"   "${TLS_OUT}/ca.crt"

  echo "  - Validating MSP files exist"
  [[ -d "${MSP_DIR}/signcerts" ]] || { echo "    ERROR: ${MSP_DIR}/signcerts missing"; exit 1; }
  [[ -d "${MSP_DIR}/cacerts"   ]] || { echo "    ERROR: ${MSP_DIR}/cacerts missing"; exit 1; }
  # keystore may be empty (soft enrolls); don’t fail if absent.

  echo "  - Applying secret ${ORDERER}-msp"
  # For directories, do NOT specify a key name. Let kubectl use filenames.
  kubectl create secret generic "${ORDERER}-msp" \
    --namespace "${TARGET_NS}" \
    --from-file="${MSP_DIR}/cacerts" \
    --from-file="${MSP_DIR}/signcerts" \
    $( [[ -d "${MSP_DIR}/keystore" && -n "$(ls -A "${MSP_DIR}/keystore" 2>/dev/null || true)" ]] && echo --from-file="${MSP_DIR}/keystore" ) \
    $( [[ -f "${MSP_DIR}/config.yaml" ]] && echo --from-file=config.yaml="${MSP_DIR}/config.yaml" ) \
    --dry-run=client -o yaml | kubectl apply -f -

  echo "  - Applying secret ${ORDERER}-tls"
  kubectl create secret generic "${ORDERER}-tls" \
    --namespace "${TARGET_NS}" \
    --from-file=server.crt="${TLS_OUT}/server.crt" \
    --from-file=server.key="${TLS_OUT}/server.key" \
    --from-file=ca.crt="${TLS_OUT}/ca.crt" \
    --dry-run=client -o yaml | kubectl apply -f -

  echo "  ✓ ${ORDERER} secrets applied"
done

echo "All orderer secrets created/applied in namespace '${TARGET_NS}'."

