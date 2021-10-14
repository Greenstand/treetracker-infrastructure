kubectl config use-context do-sfo2-dev-k8s-treetracker
kustomize build overlays/dev | kubectl apply -n rabbitmq-cluster --wait -f -
