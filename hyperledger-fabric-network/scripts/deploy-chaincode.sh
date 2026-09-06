#!/usr/bin/env bash
# Helm service deployment: deploy-treetracker-network.sh --component chaincode.
# This entrypoint manages packaging and Fabric lifecycle approvals/commit.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
exec python3 "$SCRIPT_DIR/lib/lifecycle.py" chaincode "$@"
