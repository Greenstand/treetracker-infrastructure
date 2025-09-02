#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  create-peer-secrets.sh \
    --namespace <k8s-namespace> \
    --peer <peerName> \
    --msp <path-to-peer-msp-dir> \
    --tls <path-to-peer-tls-dir>

Expected MSP layout:
  <msp>/cacerts/*.pem
  <msp>/signcerts/*.pem
  <msp>/keystore/*     (private key file)
  <msp>/config.yaml

Expected TLS layout (supports both naming schemes):
  <tls>/ca.crt
  <tls>/server.crt OR cert.pem
  <tls>/server.key OR key.pem
EOF
}

NS=""
PEER=""
MSP_DIR=""
TLS_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace) NS="$2"; shift 2 ;;
    --peer)      PEER="$2"; shift 2 ;;
    --msp)       MSP_DIR="$2"; shift 2 ;;
    --tls)       TLS_DIR="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

if [[ -z "${NS}" || -z "${PEER}" || -z "${MSP_DIR}" || -z "${TLS_DIR}" ]]; then
  echo "Missing/invalid args"; usage; exit 1
fi

# Validate MSP paths
CACERTS="$(ls -1 "${MSP_DIR}"/cacerts/*.pem 2>/dev/null | head -n1 || true)"
SIGNCERTS="$(ls -1 "${MSP_DIR}"/signcerts/*.pem 2>/dev/null | head -n1 || true)"
KEYFILE="$(ls -1 "${MSP_DIR}"/keystore/* 2>/dev/null | head -n1 || true)"
CONFIGYAML="${MSP_DIR}/config.yaml"

if [[ -z "${CACERTS}" || -z "${SIGNCERTS}" || -z "${KEYFILE}" || ! -f "${CONFIGYAML}" ]]; then
  echo "MSP directory is missing required files."
  echo "Checked:"
  echo "  cacerts -> ${CACERTS:-MISSING}"
  echo "  signcerts -> ${SIGNCERTS:-MISSING}"
  echo "  keystore -> ${KEYFILE:-MISSING}"
  echo "  config.yaml -> $( [[ -f "${CONFIGYAML}" ]] && echo OK || echo MISSING )"
  exit 1
fi

# Validate TLS paths (handle both naming styles)
TLS_CA="${TLS_DIR}/ca.crt"
TLS_CERT=""
TLS_KEY=""
[[ -f "${TLS_DIR}/server.crt" ]] && TLS_CERT="${TLS_DIR}/server.crt"
[[ -f "${TLS_DIR}/cert.pem"   ]] && TLS_CERT="${TLS_DIR}/cert.pem"
[[ -f "${TLS_DIR}/server.key" ]] && TLS_KEY="${TLS_DIR}/server.key"
[[ -f "${TLS_DIR}/key.pem"    ]] && TLS_KEY="${TLS_DIR}/key.pem"

if [[ ! -f "${TLS_CA}" || -z "${TLS_CERT}" || -z "${TLS_KEY}" ]]; then
  echo "TLS directory is missing required files."
  echo "Checked:"
  echo "  ca.crt -> $( [[ -f "${TLS_CA}" ]] && echo OK || echo MISSING )"
  echo "  cert   -> ${TLS_CERT:-MISSING} (expected server.crt or cert.pem)"
  echo "  key    -> ${TLS_KEY:-MISSING}  (expected server.key or key.pem)"
  exit 1
fi

MSP_SECRET="${PEER}-msp"
TLS_SECRET="${PEER}-tls"

echo "Creating/updating secrets in namespace '${NS}' for ${PEER} …"

# Delete if exist (idempotent)
kubectl -n "${NS}" delete secret "${MSP_SECRET}" --ignore-not-found
kubectl -n "${NS}" delete secret "${TLS_SECRET}" --ignore-not-found

# Create MSP secret
kubectl -n "${NS}" create secret generic "${MSP_SECRET}" \
  --from-file=cacerts="$(dirname "${CACERTS}")" \
  --from-file=signcerts="$(dirname "${SIGNCERTS}")" \
  --from-file=keystore="$(dirname "${KEYFILE}")" \
  --from-file=config.yaml="${CONFIGYAML}"

# Create TLS secret (normalized keys)
kubectl -n "${NS}" create secret generic "${TLS_SECRET}" \
  --from-file=ca.crt="${TLS_CA}" \
  --from-file=server.crt="${TLS_CERT}" \
  --from-file=server.key="${TLS_KEY}"

echo "Done: ${MSP_SECRET}, ${TLS_SECRET}"
