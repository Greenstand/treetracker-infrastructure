#!/bin/bash
# This script is used to deploy the keycloak to Greenstand k8s cluster

# Prompt user to choose the environment
echo "Please choose the environment to deploy the keycloak"
echo "1. dev"
echo "2. staging"
echo "3. prod"
#TODO
#read -p "Enter your choice: " choice
#deploy_env=$(node -e 'console.log(["dev", "staging", "prod"][process.argv[1] - 1])' $choice)
choice=1
deploy_env='dev'
echo "The environment to deploy is: $(echo ${deploy_env})"
#TODO
#read -p "Enter any key to continue: " key

# check the k8s cluster
echo "Checking the k8s cluster"
current_k8s_cluster=$(kubectl config current-context)
echo "The current k8s cluster is: ${current_k8s_cluster}"
#TODO here we use the name in config/context, it might be problematic
# maybe a cluster configmap is good to have: https://stackoverflow.com/questions/38242062/how-to-get-kubernetes-cluster-name-from-k8s-api
is_cluster_ok=$(node ./lib/js/checkK8sClusterNameByEnv.js ${deploy_env} ${current_k8s_cluster})
if [ "$is_cluster_ok" != "true" ]; then
  echo "The current k8s cluster is wrong, please switch to the correct cluster"
  exit 1
fi

ansible-playbook lib/playbook.yml  --extra-vars "deploy_env=${deploy_env}"


