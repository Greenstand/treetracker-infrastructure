#!/bin/sh 

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo 'Username:'
read USERNAME

echo 'Password:'
read PASSWORD

echo 'Cluster Name: rabbitmqcluster-main.rabbitmq-cluster'

CONNECTION_STRING=amqp://$USERNAME:$PASSWORD@rabbitmqcluster-main.rabbitmq-cluster
echo $CONNECTION_STRING

${__dir}/create-secret.sh -r rabbitmq-connection -k messageQueue -s $CONNECTION_STRING
