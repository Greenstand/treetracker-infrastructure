#!/bin/bash
sudo add-apt-repository universe
sudo apt-get update
sudo apt-get install libffi-dev libssl-dev software-properties-common --yes
sudo apt-get install node-gyp npm --yes
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && chmod +x get-helm.sh && rm get_helm.sh
sudo apt-get install python3-dev python3-pip python3-docker --yes
pip3 install ansible docker --upgrade
ansible-galaxy collection install community.kubernetes
pip3 install --upgrade --user openshift
