#! /bin/bash
set -e
kubectl config get-contexts

echo 'Namespace:'
read NAMESPACE

echo 'Secret resource name:'
read RESOURCE_NAME

echo 'Key name:'
read KEY_NAME

echo 'Secret value:'
read SECRET

echo "echo -n $SECRET | kubectl -n $NAMESPACE create secret generic $RESOURCE_NAME --dry-run=client --from-file=$KEY_NAME=/dev/stdin -o yaml >$RESOURCE_NAME-raw-secret.yaml"

echo -n $SECRET | kubectl -n $NAMESPACE create secret generic $RESOURCE_NAME --dry-run=client --from-file=$KEY_NAME=/dev/stdin -o yaml > $RESOURCE_NAME-raw-secret.yaml

kubectl config get-contexts

echo 'kubectl context:'
read CONTEXT

kubectl config use-context $CONTEXT

echo 'sealing..'
echo "kubeseal -n $NAMESPACE -o yaml <$RESOURCE_NAME-raw-secret.yaml >$RESOURCE_NAME-sealed-secret.yaml"
kubeseal -n $NAMESPACE -o yaml <$RESOURCE_NAME-raw-secret.yaml >$RESOURCE_NAME-sealed-secret.yaml
echo 'done..'

rm $RESOURCE_NAME-raw-secret.yaml
