kubectl config use-context do-nyc1-treetracker-cluster-production
kustomize build overlays/prod | kubectl apply -n rabbitmq-cluster --wait -f -
