#! /bin/bash
set -e

while getopts r:k: flag
do
    case "${flag}" in
        r) RESOURCE_NAME=${OPTARG};;
        k) KEY_NAME=${OPTARG};;
    esac
done


echo 'Namespace:'
read NAMESPACE

echo 'Secret resource name:'
if [ -z "$RESOURCE_NAME" ];
then
  read RESOURCE_NAME
else
  echo $RESOURCE_NAME
fi

echo 'Key name:'
if [ -z "$KEY_NAME" ];
then
  read KEY_NAME
else
  echo $KEY_NAME
fi

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
