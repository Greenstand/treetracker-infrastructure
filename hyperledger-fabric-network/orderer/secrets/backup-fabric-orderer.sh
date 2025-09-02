#!/usr/bin/env bash
set -euo pipefail

NS="${NS:-hlf-orderer}"
RELEASE="${RELEASE:-fabric-orderer}"
STAMP="$(date +%F-%H%M%S)"
OUT="${OUT:-$PWD/${RELEASE}-backup-$STAMP}"

mkdir -p "$OUT"

echo "==> Saving Helm release state"
helm get values "$RELEASE" -n "$NS" > "$OUT/values.yaml"
helm get all "$RELEASE" -n "$NS"   > "$OUT/helm-get-all.txt"
helm status   "$RELEASE" -n "$NS"  > "$OUT/helm-status.txt"

echo "==> Saving Helm release secrets (the canonical Helm state)"
kubectl -n "$NS" get secret \
  -l "owner=helm,name=${RELEASE}" \
  -o yaml > "$OUT/helm-release-secrets.yaml" || true

echo "==> Saving chart-rendered manifests (what Helm applied)"
# If you still have the chart folder handy; otherwise skip
helm template "$RELEASE" . -n "$NS" > "$OUT/rendered-manifests.yaml" || true

echo "==> Exporting Kubernetes objects (live state)"
kubectl -n "$NS" get \
  statefulsets,deployments,daemonsets,replicasets,pods,services,endpoints,ingresses \
  -o yaml > "$OUT/workloads.yaml"

kubectl -n "$NS" get \
  configmaps,secrets,serviceaccounts,roles,rolebindings \
  -o yaml > "$OUT/config-and-rbac.yaml"

kubectl -n "$NS" get \
  pvc,pv,storageclasses \
  -o yaml > "$OUT/storage.yaml" || true

echo "==> Exporting CRDs used by the release (if any)"
# Adjust kinds if you have CRDs; left generic
kubectl get crd -o name > "$OUT/crd-list.txt"
# You can selectively dump CRDs your chart uses:
# kubectl get <your-cr-kind> -A -o yaml > "$OUT/crd-objects.yaml"

echo "==> Export MSP/TLS secrets individually (easier restore)"
mkdir -p "$OUT/secrets"
for s in $(kubectl -n "$NS" get secret \
           | awk '/orderer[0-9]-(msp|tls)/{print $1}'); do
  d="$OUT/secrets/$s"
  mkdir -p "$d"
  # Expand each key to a file
  for k in $(kubectl -n "$NS" get secret "$s" -o json \
              | jq -r '.data | keys[]'); do
    kubectl -n "$NS" get secret "$s" -o jsonpath="{.data.$k}" \
      | base64 -d > "$d/$k"
  done
done

echo "==> Capture ConfigMaps used by orderers"
kubectl -n "$NS" get cm -o name \
  | grep -E 'fabric-orderer|orderer' \
  | xargs -r kubectl -n "$NS" get -o yaml > "$OUT/configmaps.yaml" || true

echo "==> (Optional) include genesis/join blocks if you keep them locally"
# Adjust paths to where you keep them:
for f in ~/hyperledger-fabric-network/config/genesis.block \
         ~/hyperledger-fabric-network/config/*.block \
         ~/hyperledger-fabric-network/config/*.tx; do
  [ -f "$f" ] && cp -v "$f" "$OUT"/ || true
done

echo "==> Creating archive"
tar -C "$(dirname "$OUT")" -czf "${OUT}.tar.gz" "$(basename "$OUT")"
sha256sum "${OUT}.tar.gz" > "${OUT}.tar.gz.sha256"

echo "==> (Optional) Encrypt archive with GPG"
# Uncomment to encrypt
# gpg --symmetric --cipher-algo AES256 -o "${OUT}.tar.gz.gpg" "${OUT}.tar.gz"

echo "Backup written to: ${OUT}.tar.gz"

