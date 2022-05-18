kubectl config use-context do-sfo2-dev-k8s-treetracker
python3 list_tags_for_deployments.py | grep treetracker > dev.out

kubectl config use-context do-sfo2-test-k8s-treetracker
python3 list_tags_for_deployments.py | grep treetracker > test.out


vimdiff dev.out test.out
