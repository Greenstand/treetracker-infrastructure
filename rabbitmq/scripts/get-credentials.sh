kubectl get rabbitmqcluster  rabbitmqcluster-sample \
-ojsonpath='Name: {.status.admin.serviceReference.name} -- Namespace: {.status.admin.serviceReference.namespace}'
echo  ""
echo  -n "username "
#first get the name of default user secret
#kubectl get rabbitmqcluster rabbitmqcluster-sample -ojsonpath='{.status.defaultUser.secretReference.name}'
kubectl get secret rabbitmqcluster-sample-default-user -o jsonpath="{.data.username}" | base64 --decode
echo  ""
echo  -n "password "
kubectl get secret rabbitmqcluster-sample-default-user -o jsonpath="{.data.password}" | base64 --decode
echo  ""
