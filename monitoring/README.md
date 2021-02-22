### How do I run these playbooks?

You'll need to be authenticated to the clusters first, refer to the [README](../scripts/README.md) in the scripts folder to do so.
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
