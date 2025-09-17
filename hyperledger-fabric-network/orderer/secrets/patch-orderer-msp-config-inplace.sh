#!/usr/bin/env bash
# patch-orderer-msp-config-inplace.sh
set -euo pipefail

NS="hlf-orderer"

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

B64_CFG="$(printf "%s" "$CONFIG_YAML" | base64 | tr -d '\n')"

for i in 0 1 2 3 4; do
  name="orderer${i}-msp"
  echo "Patching $name ..."
  # ensure secret exists
  kubectl -n "$NS" get secret "$name" >/dev/null
  # add/replace config.yaml
  kubectl -n "$NS" patch secret "$name" \
    --type=merge \
    -p "{\"data\":{\"config.yaml\":\"${B64_CFG}\"}}"
  # verify
  kubectl -n "$NS" get secret "$name" -o jsonpath='{.data.config\.yaml}' >/dev/null
  echo "  ✓ config.yaml present"
done

echo "All MSP secrets patched."

