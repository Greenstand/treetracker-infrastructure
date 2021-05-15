# PGPool settings

### To generate the config by kustomize and apply to kubernates

```
kubectl --kubeconfig=../dev-k8s-treetracker-kubeconfig.yaml kustomize deployment/overlays/development/ | kubectl apply --kubeconfig=../dev-k8s-treetracker-kubeconfig.yaml -f -
```

### To test connect to the db

Get the pod name:

```
kubectl --kubeconfig=../dev-k8s-treetracker-kubeconfig.yaml get pods -n pgpool
```

For word the port:

```
kubectl --kubeconfig=../dev-k8s-treetracker-kubeconfig.yaml port-forward [pod-name] 9999:9999 -n pgpool
```

Connect to DB:

```
pgpool> psql -p 9999 -h 127.0.0.1 -U [username] [dbname]

```

