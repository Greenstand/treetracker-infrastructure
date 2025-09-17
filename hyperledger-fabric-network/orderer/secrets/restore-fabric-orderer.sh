#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-hlf-orderer}"
RELEASE="${RELEASE:-fabric-orderer}"
ARCHIVE="${1:-}"
[ -z "$ARCHIVE" ] && { echo "Usage: $0 <backup-archive.tar.gz>"; exit 1; }

WORK="/tmp/restore-$$"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

echo "==> Extracting archive"
tar -xzf "$ARCHIVE" -C "$WORK"
BACKUP_DIR="$(find "$WORK" -maxdepth 1 -type d -name "${RELEASE}-backup-*")"

echo "==> Ensure namespace"
kubectl get ns "$NS" >/dev/null 2>&1 || kubectl create ns "$NS"

echo "==> Restore ConfigMaps (generic dump)"
if [ -s "$BACKUP_DIR/configmaps.yaml" ]; then
  kubectl -n "$NS" apply -f "$BACKUP_DIR/configmaps.yaml"
fi

echo "==> Restore MSP/TLS secrets"
if [ -d "$BACKUP_DIR/secrets" ]; then
  for dir in "$BACKUP_DIR"/secrets/*; do
    s="$(basename "$dir")"
    echo "  -> $s"
    kubectl -n "$NS" delete secret "$s" --ignore-not-found
    # Rebuild secret from files in the dir
    kubectl -n "$NS" create secret generic "$s" $(printf -- ' --from-file=%s' "$dir"/*)
  done
fi

echo "==> Reinstall/upgrade Helm release with saved values"
if [ -f "$BACKUP_DIR/values.yaml" ]; then
  # If you have the chart directory locally:
  helm upgrade --install "$RELEASE" ./ -n "$NS" -f "$BACKUP_DIR/values.yaml"
  # If you do NOT have the chart, you can restore from the helm release secret instead:
  # kubectl -n "$NS" apply -f "$BACKUP_DIR/helm-release-secrets.yaml"
  # Then 'helm history' should pick it up; you may still need the chart source to re-install.
else
  echo "WARN: values.yaml not found; skipping helm upgrade/install."
fi

echo "==> (Optional) restore blocks"
# Example: copy genesis.block into a CM for convenience
if [ -f "$BACKUP_DIR/genesis.block" ]; then
  kubectl -n "$NS" create cm genesis-block --from-file=genesis.block \
    --dry-run=client -o yaml | kubectl apply -f -
fi

echo "Restore complete."

