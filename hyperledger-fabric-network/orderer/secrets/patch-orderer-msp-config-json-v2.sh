#!/usr/bin/env bash
# patch-orderer-msp-config-json-v2.sh
set -xeuo pipefail

NS="hlf-orderer"

CFG="$(cat <<'YAML'
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
)"
B64_CFG="$(printf '%s' "$CFG" | base64 | tr -d '\n')"

for i in 0 1 2 3 4; do
  name="orderer${i}-msp"
  echo "==> Patching $name"
  kubectl -n "$NS" patch secret "$name" --type='json' \
    -p="[ {\"op\":\"add\",\"path\":\"/data/config.yaml\",\"value\":\"$B64_CFG\"} ]" \
  || kubectl -n "$NS" patch secret "$name" --type='json' \
    -p="[ {\"op\":\"replace\",\"path\":\"/data/config.yaml\",\"value\":\"$B64_CFG\"} ]"
  # verify
  kubectl -n "$NS" get secret "$name" -o jsonpath='{.data.config\.yaml}' | base64 -d | sed -n '1,3p'
done

echo "All MSP secrets now include config.yaml."


