#!/usr/bin/env bash
set -Eeuo pipefail

# === Defaults ===
NS="hlf-ca"
ARCHIVE=""
LABEL_SELECTOR="app in (root-ca,greenstand-ca,cbo-ca,investor-ca,verifier-ca)"
APPLY_K8S="true"
RESTORE_DATA="true"
DRY_RUN="false"
VERBOSE="false"

usage() {
  cat <<'EOF'
Usage:
  restore-ca.sh --archive <fabric-ca-backup-*.tgz>
                [--namespace <ns>]
                [--label "<k8s label selector>"]
                [--no-k8s] [--no-data]
                [--dry-run] [--verbose]

What it does:
  1) Extracts the backup archive to a temp dir
  2) (default) Applies Secrets/ConfigMaps from the backup into the target namespace (namespaced swap if needed)
  3) (default) Restores CA server data (server-etc.tgz + server-data.tgz) into each CA pod discovered by label:
       - copies tarballs into the pod
       - extracts to /etc/hyperledger/fabric-ca-server and /data/hyperledger/fabric-ca-server
       - then deletes the pod to let Deployment recreate it with the restored data

Options:
  --archive <file>   Path to backup archive (required)
  --namespace <ns>   Target namespace (default: hlf-ca)
  --label "<expr>"   Label selector for CA pods (default covers: root/greenstand/cbo/investor/verifier)
  --no-k8s           Skip restoring K8s Secrets/ConfigMaps
  --no-data          Skip restoring CA server data into pods
  --dry-run          Show what would happen, do not modify cluster
  --verbose          Extra logs

Examples:
  ./restore-ca.sh --archive fabric-ca-backup-2025-08-08_201755.tgz
  ./restore-ca.sh --archive ./backup.tgz --namespace test-ca --label 'app in (root-ca)'
  ./restore-ca.sh --archive ./backup.tgz --no-data   # only re-apply secrets/configmaps
EOF
}

log() { echo "[$(date +%H:%M:%S)] $*"; }
vlog() { [[ "$VERBOSE" == "true" ]] && echo "[$(date +%H:%M:%S)] $*" || true; }

# === Parse args ===
while [[ $# -gt 0 ]]; do
  case "$1" in
    --archive) ARCHIVE="$2"; shift 2;;
    --namespace) NS="$2"; shift 2;;
    --label) LABEL_SELECTOR="$2"; shift 2;;
    --no-k8s) APPLY_K8S="false"; shift;;
    --no-data) RESTORE_DATA="false"; shift;;
    --dry-run) DRY_RUN="true"; shift;;
    --verbose) VERBOSE="true"; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

[[ -z "$ARCHIVE" ]] && { echo "ERROR: --archive is required"; usage; exit 1; }
[[ -f "$ARCHIVE" ]] || { echo "ERROR: archive not found: $ARCHIVE"; exit 1; }

# === Prep temp workspace ===
WORKDIR="$(mktemp -d -t ca-restore-XXXXXX)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

log "Extracting archive: $ARCHIVE"
tar -xzf "$ARCHIVE" -C "$WORKDIR"

# Sanity: show what we’ve got
vlog "Archive layout:"
vlog "$(find "$WORKDIR" -maxdepth 2 -type f | sed "s|$WORKDIR/||")"

# === 1) Restore K8s objects (Secrets/ConfigMaps) ===
if [[ "$APPLY_K8S" == "true" ]]; then
  for f in k8s-secrets-*.yaml k8s-configmaps-*.yaml; do
    SRC="$WORKDIR/$f"
    [[ -f "$SRC" ]] || { vlog "Skip missing $f"; continue; }
    # Swap namespace in the manifests if needed
    TMP="$WORKDIR/$f.patched"
    # Replace only explicit "namespace: <old>" occurrences. If no namespace lines present, we’ll apply with -n.
    sed "s/^\(\s*namespace:\s*\).*/\1$NS/" "$SRC" > "$TMP" || cp "$SRC" "$TMP"

    if [[ "$DRY_RUN" == "true" ]]; then
      log "[DRY-RUN] kubectl apply -n $NS -f $TMP"
    else
      log "Applying $(basename "$TMP") to namespace $NS"
      kubectl apply -n "$NS" -f "$TMP"
    fi
  done
else
  log "Skipping K8s Secrets/ConfigMaps restore (--no-k8s)"
fi

# === 2) Discover CA pods in target namespace ===
if [[ "$RESTORE_DATA" == "true" ]]; then
  log "Discovering CA pods in namespace: $NS (selector: $LABEL_SELECTOR)"
  mapfile -t CA_PODS < <(kubectl get pods -n "$NS" -l "$LABEL_SELECTOR" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')
  if [[ ${#CA_PODS[@]} -eq 0 ]]; then
    echo "ERROR: No CA pods matched selector in namespace $NS"; exit 1
  fi
  printf "  Found CA pods:\n"; for p in "${CA_PODS[@]}"; do printf "   - %s\n" "$p"; done

  # Build a mapping of <pod> -> <archive dir> by using the app label (e.g. root-ca) and matching a dir like root-ca-*
  for POD in "${CA_PODS[@]}"; do
    APP=$(kubectl -n "$NS" get pod "$POD" -o jsonpath='{.metadata.labels.app}')
    if [[ -z "$APP" ]]; then
      echo "WARN: Pod $POD has no 'app' label; trying to infer from pod name"
      APP="${POD%-*}"  # strip trailing hash if any
    fi

    # Find dir in archive that starts with APP-
    MATCH_DIR="$(find "$WORKDIR" -maxdepth 1 -type d -name "${APP}-*" | head -n1 || true)"
    if [[ -z "$MATCH_DIR" ]]; then
      echo "WARN: No archive dir matching '${APP}-*' for pod $POD; skipping data restore for this pod"
      continue
    fi

    ETC_TGZ="$MATCH_DIR/server-etc.tgz"
    DATA_TGZ="$MATCH_DIR/server-data.tgz"
    if [[ ! -f "$ETC_TGZ" && ! -f "$DATA_TGZ" ]]; then
      echo "WARN: No server-*.tgz for $APP in archive; skipping $POD"
      continue
    fi

    log "Restoring CA data into pod: $POD  (from: $(basename "$MATCH_DIR"))"

    if [[ "$DRY_RUN" == "true" ]]; then
      [[ -f "$ETC_TGZ" ]] && log "[DRY-RUN] kubectl -n $NS cp $ETC_TGZ $POD:/tmp/server-etc.tgz"
      [[ -f "$DATA_TGZ" ]] && log "[DRY-RUN] kubectl -n $NS cp $DATA_TGZ $POD:/tmp/server-data.tgz"
      log "[DRY-RUN] kubectl -n $NS exec $POD -- sh -lc 'set -e; [[ -f /tmp/server-etc.tgz ]] && tar -C / -xzf /tmp/server-etc.tgz; [[ -f /tmp/server-data.tgz ]] && tar -C / -xzf /tmp/server-data.tgz; rm -f /tmp/server-*.tgz'"
      log "[DRY-RUN] kubectl -n $NS delete pod $POD"
      continue
    fi

    # Copy tarballs into the pod
    [[ -f "$ETC_TGZ" ]] && kubectl -n "$NS" cp "$ETC_TGZ" "$POD":/tmp/server-etc.tgz
    [[ -f "$DATA_TGZ" ]] && kubectl -n "$NS" cp "$DATA_TGZ" "$POD":/tmp/server-data.tgz

    # Extract in-place; paths inside tarballs are already absolute (/etc/... and /data/...)
    kubectl -n "$NS" exec "$POD" -- sh -lc '
      set -e
      [[ -f /tmp/server-etc.tgz ]] && tar -C / -xzf /tmp/server-etc.tgz || true
      [[ -f /tmp/server-data.tgz ]] && tar -C / -xzf /tmp/server-data.tgz || true
      rm -f /tmp/server-etc.tgz /tmp/server-data.tgz || true
      # show result
      ls -ld /etc/hyperledger/fabric-ca-server || true
      ls -ld /data/hyperledger/fabric-ca-server || true
    '

    # Bounce the pod so CA re-reads files from disk
    log "Restarting pod $POD to pick up restored data"
    kubectl -n "$NS" delete pod "$POD" --wait=false >/dev/null 2>&1 || true
  done

  log "Waiting for CA pods to become Ready..."
  kubectl -n "$NS" wait --for=condition=Ready pod -l "$LABEL_SELECTOR" --timeout=180s || true
else
  log "Skipping CA data restore (--no-data)"
fi

log "✅ Restore completed."

