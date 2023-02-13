#!/bin/sh

kubectl get -n rabbitmq-cluster rabbitmqcluster  rabbitmqcluster-main \
-ojsonpath='Name: {.status.admin.serviceReference.name} -- Namespace: {.status.admin.serviceReference.namespace}'
echo  ""
echo  -n "username "
#first get the name of default user secret
#kubectl get rabbitmqcluster rabbitmqcluster-main -ojsonpath='{.status.defaultUser.secretReference.name}'
kubectl get -n rabbitmq-cluster secret rabbitmqcluster-main-default-user -o jsonpath="{.data.username}" | base64 --decode
echo  ""
echo  -n "password "
kubectl get -n rabbitmq-cluster secret rabbitmqcluster-main-default-user -o jsonpath="{.data.password}" | base64 --decode
echo  ""
