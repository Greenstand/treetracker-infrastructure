#!/bin/bash
doctl auth init
if [[ -z "$1" ]]; then
    echo "Select a cluster"
    echo "1) dev-k8s-treetracker"
    echo "2) test-k8s-treetracker"
    echo -n "Choice: "
    read cluster
    if [[ "$cluster" == "1" ]]; then
        cluster="dev-k8s-treetracker"
    elif [[ "$cluster" == "2" ]]; then
        cluster="test-k8s-treetracker"
    else
        echo "Invalid choice: $cluster"
        exit 1
    fi
else
    cluster="$1"
fi
doctl kubernetes cluster kubeconfig save $cluster
