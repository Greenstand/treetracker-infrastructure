### Authenticating to kubernetes clusters

1. Install doctl, `brew install doctl` on mac
2. Use `doctl auth init` and pass your DO API key
3. Save the kubeconfig relevant to the cluster, e.g. `doctl kubernetes cluster kubeconfig save dev-k8s-treetracker`
4. Switch to the context if not already switched, e.g. `kubectl config set-context do-sfo2-dev-k8s-treetracker` You can view the relevant contexts using `kubectl config view | grep treetracker`
5. Install helm 3 if not present, `brew install helm`
6. You are now ready to run any helm command/ playbooks relevant to the repo


### How do I see what's running in the cluster?

You can use `helm list -n monitoring` to see what releases there are
You can use `kubectl get pods -n monitoring` to see what's running in the monitoring namespace


### How do I view the grafana dashboard

In the future, we should probably set up ingress.
For now, you can port-forward, e.g.
```
kubectl get pods -n monitoring | grep 'grafana' | cut -d" " -f1 | xargs -I{} kubectl port-forward -n monitoring {} 3000:3000
```
to see at localhost:3000 the grafana running within the cluster

More info on how to access these things is listed [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-digitalocean-kubernetes-cluster-monitoring-with-helm-and-prometheus-operator)
