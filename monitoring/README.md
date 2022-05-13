### How do I run these playbooks?

You'll need to be authenticated to the clusters first, refer to the [README](../scripts/README.md) in the scripts folder to do so.

Examples:

```
# Install the prom operator
ansible-playbook prom-operator-playbook.yml -e @dev-values.enc --vault-password-file password_file

ansible-playbook elasticsearch-kibana-filebeat.yml
```

#### Using decrypted values

To encrypt/decrypt values, add the required password into `password_file` and run

```
ansible-vault decrypt dev-values.enc --vault-password-file password_file
# or
ansible-vault encrypt dev-values.enc --vault-password-file password_file
```

Don't commit decrypted values!

And to run the playbook, use

```
ansible-playbook prom-operator-playbook.yml -e @dev-values.enc --vault-password-file password_file
```

### How do I see what's running in the cluster?

You can use `helm list -n monitoring` to see what releases there are
You can use `kubectl get pods -n monitoring` to see what's running in the monitoring namespace

### How do I view the grafana dashboard

In the future, we should probably set up ingress.
For now, you can port-forward, e.g.
```
kubectl port-forward -n monitoring svc/prometheus-community-grafana 80:80
```
to see at localhost:3000 the grafana running within the cluster

To see grafana/alertmanager/prometheus
```
kubectl port-forward -n monitoring svc/prometheus-community-kube-alertmanager 9093:9093
kubectl port-forward -n monitoring svc/prometheus-community-kube-prometheus 9090:9090
```

There's also a mapping file for the URL https://HOSTNAME/grafana

More info on how to access these things is listed [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-digitalocean-kubernetes-cluster-monitoring-with-helm-and-prometheus-operator)


### How do I view Kibana

Kibana is accessible on URL/kibana (e.g. dev-k8s.treetracker.org/kibana)


### Migrating from the older grafana to the newer version

1. Run `ansible-playbook prom-operator-playbook.yml -e @<env>-values.enc --vault-password-file password_file`
1. If an error appears, next run
```bash
kubectl delete crd prometheuses.monitoring.coreos.com prometheusrules.monitoring.coreos.com alertmanagers.monitoring.coreos.com alertmanagerconfigs.monitoring.coreos.com
```
1. Rerun the first command
1. Cleanup any old pvcs instead of migrating
```
kubectl delete --namespace=monitoring pvc prometheus-prometheus-community-kube-prometheus-db-prometheus-prometheus-community-kube-prometheus-0 alertmanager-prometheus-community-kube-alertmanager-db-alertmanager-prometheus-community-kube-alertmanager-0
```

### Cleaning up the old elasticsearch/kibana/filebeat install
Run `./roles/elasticsearch/cleanup.sh`
