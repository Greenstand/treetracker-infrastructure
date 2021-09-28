# PGPool settings

### To generate the config by kustomize and apply to kubernates

```
kubectl --kubeconfig=[path to kubernates config] kustomize deployment/overlays/development/ | kubectl apply --kubeconfig=[path to kubernates config] -f -
```

### To test connect to the db

Get the pod name:

```
kubectl --kubeconfig=[path to kubernates config] get pods -n pgpool
```

For word the port:

```
kubectl --kubeconfig=[path to kubernates config] port-forward [pod-name] 9999:9999 -n pgpool
```

Connect to DB:

```
pgpool> psql -p 9999 -h 127.0.0.1 -U [username] [dbname]

```

