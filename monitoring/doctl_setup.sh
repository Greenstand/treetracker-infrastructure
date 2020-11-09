#!/bin/bash
doctl auth init
doctl kubernetes cluster kubeconfig save $1
kubectl config set-context $2
