#!/usr/bin/env bash
# patch-orderer-msp-config-json.sh
set -xeuo pipefail

NS="hlf-orderer"
read -r -d '' CFG <<'YAML'
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
B64_CFG="$(printf "%s" "$CFG" | base64 | tr -d '\n')"

for i in 0 1 2 3 4; do
  name="orderer${i}-msp"
  echo "==> Patching $name"
  # add OR replace depending on existence
  kubectl -n "$NS" patch secret "$name" --type='json' \
    -p="[ {\"op\":\"add\",\"path\":\"/data/config.yaml\",\"value\":\"$B64_CFG\"} ]" \
  || kubectl -n "$NS" patch secret "$name" --type='json' \
    -p="[ {\"op\":\"replace\",\"path\":\"/data/config.yaml\",\"value\":\"$B64_CFG\"} ]"

  # show keys present
  kubectl -n "$NS" get secret "$name" -o json | jq -r '.data | keys | join(",")'
done

echo "All MSP secrets now include config.yaml."

