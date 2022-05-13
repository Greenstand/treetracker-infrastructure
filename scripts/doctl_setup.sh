#!/bin/bash
doctl auth init
CLUSTER=$1
if [[ -z "$CLUSTER" ]]; then
    echo "choose a cluster:"
    doctl kubernetes cluster list --format Name
    exit 2
fi
doctl kubernetes cluster kubeconfig save $1
