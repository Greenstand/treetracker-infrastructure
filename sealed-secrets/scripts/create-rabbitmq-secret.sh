#! /bin/bash 

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo 'Username:'
read USERNAME

echo 'Password:'
read PASSWORD

echo 'Cluster Name: rabbitmqcluser-main'

CONNECTION_STRING=amqp://$USERNAME:$PASSWORD@rabbitmqcluster-main
echo $CONNECTION_STRING

${__dir}/create-secret.sh -r rabbitmq-connection -k messageQueue -s $CONNECTION_STRING
