#!/bin/bash

ORDERERS=(orderer0 orderer1 orderer2 orderer3 orderer4)
ORG_PATH=./crypto-config/ordererOrganizations/example.com/orderers

for ORDERER in "${ORDERERS[@]}"; do
  echo "Creating secrets for $ORDERER..."

  kubectl create secret generic ${ORDERER}-tls \
    --from-file=server.crt=${ORG_PATH}/${ORDERER}.example.com/tls/server.crt \
    --from-file=server.key=${ORG_PATH}/${ORDERER}.example.com/tls/server.key \
    --from-file=ca.crt=${ORG_PATH}/${ORDERER}.example.com/tls/ca.crt \
    -n hyperledger-fabric

  kubectl create secret generic ${ORDERER}-msp \
    --from-file=${ORG_PATH}/${ORDERER}.example.com/msp \
    -n hyperledger-fabric

  echo "$ORDERER secrets created."
done

