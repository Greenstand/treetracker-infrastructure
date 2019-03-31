#!/bin/bash
if [[ -z "$1" ]]; then
  echo "Branch name is required as first argument"
  exit 1
fi

ansible-playbook build_and_deploy.yml -e "version="$1
