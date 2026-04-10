#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# Hyperledger Fabric CA backup script
#   - Backs up CA server data dirs from pods (DB, certs, CSR, keys)
#   - Backs up fabric-ca-client enrollments from client pod
#   - Backs up K8s secrets & configmaps in the CA namespace
#   - Backs up Helm release configs in the CA namespace
#
# Usage:
#   ./backup-ca.sh [--namespace hlf-ca] [--client-pod fabric-ca-client-0] \
#                  [--label "app.kubernetes.io/component=fabric-ca"]
#
# Result:
#   ./fabric-ca-backup-YYYY-MM-DD_HHMMSS.tgz
#
# Notes:
# - Requires: kubectl, jq, helm (for Helm release manifests)
# - The script is read-only on the cluster; it just fetches and packages.
# ------------------------------------------------------------------------------

NS="${NS:-hlf-ca}"
CLIENT_POD="${CLIENT_POD:-fabric-ca-client-0}"
CA_LABEL="${CA_LABEL:-app in (root-ca,greenstand-ca,cbo-ca,investor-ca,verifier-ca)}"
OUTDIR="${OUTDIR:-./backup-ca}"
STAMP="$(date +%F_%H%M%S)"
ARCHIVE="fabric-ca-backup-${STAMP}.tgz"

# Parse args (tiny parser)
while [[ $# -gt 0 ]]; do
  case "$1" in
    --namespace|-n) NS="$2"; shift 2;;
    --client-pod)   CLIENT_POD="$2"; shift 2;;
    --label)        CA_LABEL="$2"; shift 2;;
    --outdir)       OUTDIR="$2"; shift 2;;
    -h|--help)
      grep -E '^# ' "$0" | sed 's/^# //'
      exit 0;;
    *)
      echo "Unknown arg: $1" >&2; exit 1;;
  esac
done

echo "Namespace         : $NS"
echo "CA selector label : $CA_LABEL"
echo "CA client pod     : $CLIENT_POD"
echo "Output dir        : $OUTDIR"
echo

mkdir -p "$OUTDIR"

# ------------------------------------------------------------------------------
# 1) Discover CA server pods (Root + Intermediate CAs)
# ------------------------------------------------------------------------------
echo ">> Discovering CA pods in $NS ..."
mapfile -t CA_PODS < <(kubectl -n "$NS" get pods -l "$CA_LABEL" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
if [[ "${#CA_PODS[@]}" -eq 0 ]]; then
  echo "No CA pods found with label: $CA_LABEL in namespace: $NS" >&2
  exit 1
fi
printf "   Found CA pods:\n"; printf "    - %s\n" "${CA_PODS[@]}"; echo

# ------------------------------------------------------------------------------
# 2) Backup CA server data from each CA pod
#    Common locations (adjust if your container image differs):
#    - /etc/hyperledger/fabric-ca-server  (config, certs, db)
#    - /data/hyperledger/fabric-ca-server (PVC mount in many charts)
# ------------------------------------------------------------------------------
for pod in "${CA_PODS[@]}"; do
  echo ">> Backing up server data from pod: $pod"

  # Use tar-from-pod to preserve perms & symlinks
  TMP_DIR="$(mktemp -d)"
  (
    set -x
    # Try both common paths; ignore if missing
    kubectl -n "$NS" exec "$pod" -- sh -lc 'tar -C / -czf - \
      etc/hyperledger/fabric-ca-server 2>/dev/null || true' > "${TMP_DIR}/server-etc.tgz"
    kubectl -n "$NS" exec "$pod" -- sh -lc 'tar -C / -czf - \
      data/hyperledger/fabric-ca-server 2>/dev/null || true' > "${TMP_DIR}/server-data.tgz"
  )

  DEST_DIR="${OUTDIR}/${pod}"
  mkdir -p "$DEST_DIR"
  # Store tarballs raw (so we can untar to exact paths on restore)
  mv "${TMP_DIR}/server-etc.tgz"  "${DEST_DIR}/server-etc.tgz"
  mv "${TMP_DIR}/server-data.tgz" "${DEST_DIR}/server-data.tgz"
  rm -rf "$TMP_DIR"

  echo "   Saved: ${DEST_DIR}/server-etc.tgz, server-data.tgz"
done
echo

# ------------------------------------------------------------------------------
# 3) Backup the fabric-ca-client enrollments
#    Typical path: /data/hyperledger/fabric-ca-client
#    (Your earlier logs confirm this path.)
# ------------------------------------------------------------------------------
echo ">> Backing up fabric-ca-client enrollments from pod: $CLIENT_POD"
if kubectl -n "$NS" get pod "$CLIENT_POD" >/dev/null 2>&1; then
  kubectl -n "$NS" exec "$CLIENT_POD" -- sh -lc 'tar -C / -czf - data/hyperledger/fabric-ca-client' \
    > "${OUTDIR}/fabric-ca-client.tgz"
  echo "   Saved: ${OUTDIR}/fabric-ca-client.tgz"
else
  echo "   WARN: client pod $CLIENT_POD not found; skipping client enrollments"
fi
echo

# ------------------------------------------------------------------------------
# 4) Backup Kubernetes secrets & configmaps in CA namespace
#    (This captures TLS certs/keys, CA configs, issuers, etc.)
# ------------------------------------------------------------------------------
echo ">> Exporting all secrets & configmaps in namespace: $NS"
kubectl -n "$NS" get secret -o yaml > "${OUTDIR}/k8s-secrets-${NS}.yaml"
kubectl -n "$NS" get cm     -o yaml > "${OUTDIR}/k8s-configmaps-${NS}.yaml"
echo "   Saved: k8s-secrets-${NS}.yaml, k8s-configmaps-${NS}.yaml"
echo

# ------------------------------------------------------------------------------
# 5) Backup Helm release configs for the namespace (if helm is in use here)
# ------------------------------------------------------------------------------
if command -v helm >/dev/null 2>&1; then
  echo ">> Capturing Helm releases in $NS"
  mapfile -t HELM_RELEASES < <(helm list -n "$NS" -o json | jq -r '.[].name')
  if [[ "${#HELM_RELEASES[@]}" -gt 0 ]]; then
    for rel in "${HELM_RELEASES[@]}"; do
      mkdir -p "${OUTDIR}/helm-releases/${rel}"
      # Get history & manifest
      helm history "$rel" -n "$NS" -o yaml > "${OUTDIR}/helm-releases/${rel}/history.yaml" || true
      helm get all "$rel" -n "$NS" > "${OUTDIR}/helm-releases/${rel}/all.txt" || true
      # If you store Helm release objects as secrets, grab them too:
      kubectl -n "$NS" get secret -l "owner=helm,name=${rel}" -o yaml \
        > "${OUTDIR}/helm-releases/${rel}/release-secrets.yaml" || true
    done
    echo "   Saved Helm release details under ${OUTDIR}/helm-releases/"
  else
    echo "   No Helm releases found in ${NS}."
  fi
else
  echo ">> helm not found in PATH; skipping Helm release capture."
fi
echo

# ------------------------------------------------------------------------------
# 6) Sanity: list what we collected
# ------------------------------------------------------------------------------
echo ">> Collected artifacts:"
( cd "$OUTDIR" && find . -maxdepth 3 -type f | sed 's@^\./@@' | sort )

# ------------------------------------------------------------------------------
# 7) Package
# ------------------------------------------------------------------------------
echo
echo ">> Creating archive: ${ARCHIVE}"
tar -C "$(dirname "$OUTDIR")" -czf "$ARCHIVE" "$(basename "$OUTDIR")"

echo
echo "✅ CA backup complete:"
echo "   $(pwd)/${ARCHIVE}"
echo "   (Keep this archive outside Git; rotate & encrypt as needed.)"

