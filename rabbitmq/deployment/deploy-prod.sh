#!/bin/bash
set -euo pipefail

# Fix for 'Ansible collection ansible.builtin was not found' error in CI/CD - ensures consistent Python interpreter for Ansible
export ANSIBLE_PYTHON_INTERPRETER=/usr/bin/python3

kubectl config use-context do-nyc1-treetracker-cluster-production
kustomize build overlays/prod | kubectl apply -n rabbitmq-cluster --wait -f -