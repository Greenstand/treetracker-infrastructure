#!/bin/bash
doctl auth init
CLUSTER=$1
if [[ -z "$CLUSTER" ]]; then
    echo "choose a cluster"
    echo """* dev-k8s-treetracker
* test-k8s-treetracker"""
    exit 2
fi
doctl kubernetes cluster kubeconfig save $1
