#!/bin/bash
doctl auth init
doctl kubernetes cluster kubeconfig save test-k8s-treetracker

