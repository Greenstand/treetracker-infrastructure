#!/bin/sh

kubectl config use-context do-sfo2-test-k8s-treetracker
kustomize build overlays/test | kubectl apply -n rabbitmq-cluster --wait -f -
