#!/usr/bin/env bash
# Optional isolated profile test. Synthetic identities exist only in container tmpfs.
set -euo pipefail
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd -- "$SCRIPT_DIR/.." && pwd)
TOOLS_IMAGE=hyperledger/fabric-tools@sha256:1d163b2513453637c2eb8ffe00bfb367f6edb2fb824604818f30646f552c9f42
docker run --rm --pull=never --network none --read-only \
  --tmpfs /work:rw,nosuid,size=128m --tmpfs /tmp:rw,nosuid,size=32m \
  --mount "type=bind,source=$REPO_DIR/config,target=/source,readonly" \
  --workdir /work --entrypoint /bin/bash "$TOOLS_IMAGE" -ec '
    cryptogen generate --config=/source/crypto-config.yaml --output=/work/crypto
    mkdir -p /work/config/msp /work/config/consenters
    cp /source/configtx.yaml /work/config/configtx.yaml
    cp -R /work/crypto/peerOrganizations/cbo.fabric.example.com/msp /work/config/msp/cbo
    cp -R /work/crypto/peerOrganizations/greenstand.fabric.example.com/msp /work/config/msp/greenstand
    cp -R /work/crypto/ordererOrganizations/hlf-orderer.svc.cluster.local/msp /work/config/msp/orderer
    for prefix in orderer v2-orderer; do
      for i in 0 1 2 3 4; do
        cp "/work/crypto/ordererOrganizations/hlf-orderer.svc.cluster.local/orderers/${prefix}${i}.hlf-orderer.svc.cluster.local/tls/server.crt" "/work/config/consenters/${prefix}${i}-tls.pem"
      done
    done
    configtxgen -configPath /work/config -profile TreetrackerChannel -channelID treetracker -outputBlock /work/original.block
    configtxgen -configPath /work/config -profile TreetrackerV2Channel -channelID treetracker-v2 -outputBlock /work/v2.block
    test -s /work/original.block
    test -s /work/v2.block
  '
