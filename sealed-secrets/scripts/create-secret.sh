#! /bin/bash
set -e

while getopts r:k:s: flag
do
    case "${flag}" in
        r) RESOURCE_NAME=${OPTARG};;
        k) KEY_NAME=${OPTARG};;
        s) SECRET_VALUE=${OPTARG};;
    esac
done

echo $SECRET_VALUE

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
if [ -z "$SECRET_VALUE" ];
then
  read SECRET_VALUE
else
  echo $SECRET_VALUE
fi

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
