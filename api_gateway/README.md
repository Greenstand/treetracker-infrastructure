### Getting logged into the cluster

See the [monitoring readme](../monitoring/README.md) for info on how to auth to the k8s clusters

### What is ambassador?

An API gateway to allow you to wire up various services

It has some interesting setup that we followed from [here](https://www.getambassador.io/docs/latest/topics/install/helm/)

It also provides an edgectl CLI for setting up TLS termination, shown [here](https://github.com/datawire/ambassador-docs/blob/master/user-guide/getting-started.md)

The playbooks within here require helm to run.

Once you have the playbook run in the cluster, you can run `edgectl install` and follow the on screen prompts.

`dev` -> `edgectl login dev-k8s.treetracker.org`

### How install into kubernetes cluster

#### Install tools
1. Install doctl, brew install doctl on mac
1. Install helm 3 if not present, brew install helm on mac
1. Install ansible if not present

#### Connect and install helm chart using ansible
1. Use `doctl auth init` and pass your DO API key
1. Save the kubeconfig relevant to the cluster, e.g. `doctl kubernetes cluster kubeconfig save dev-k8s-treetracker`
    1. Switch to the context if not already switched, e.g. kubectl config set-context do-sfo2-dev-k8s-treetracker 
1. Run ansible to install ambassador helm chart `ansible-playbook ambassador-playbook.yml`
1. Ambassador is deployed! 
    1. Ambassdor is deployed! Ambassador metrics are also exposed and are being scraped by Prometheus.
1. Set up the dns record for this api gateway
    1. cd terraform/development (all dns managed here at this time)
    1. domain to dns.tf
    1. apply terraform
1. Connect to Ambassador and set up SSL
    1. edctl login ${domain name}
    1. click through
    1. add the host you configured in the last step and get an ssl certificate

### Ambassador health checks

Ambassador can take more than one second to answer health checks while reloading
configuration. With the chart defaults (a one-second timeout and three-second
period), these delays can trigger unnecessary restarts and drop requests in
flight. See [issue #343](https://github.com/Greenstand/treetracker-infrastructure/issues/343).

The Ambassador role sets both probes to a five-second timeout and ten-second
period, with three consecutive failures required. The chart's health endpoints
and initial delays are preserved. This also makes readiness detection less
frequent, so validate the change in development before production.

The issue reports chart version 6.5.9 in production. That chart's templates do not
render `timeoutSeconds`, so setting it in Helm values alone has no effect. The
6.7.8 version pinned in this repository supports the role's probe values.

For an existing release, apply the following patch from a Bash shell. It changes
only the two probes and avoids upgrading the installed chart. Confirm the
deployment and container are both named `ambassador`, and record their current
probe settings before applying it.

```sh
CONTEXT="your-development-context"
kubectl --context "$CONTEXT" -n ambassador get deployment ambassador -o yaml
kubectl --context "$CONTEXT" -n ambassador patch deployment ambassador \
  --type=strategic --patch-file=/dev/stdin <<'YAML'
spec:
  template:
    spec:
      containers:
        - name: ambassador
          livenessProbe:
            timeoutSeconds: 5
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            timeoutSeconds: 5
            periodSeconds: 10
            failureThreshold: 3
YAML
kubectl --context "$CONTEXT" -n ambassador rollout status deployment/ambassador
```

Watch pod restart counts and new probe failures for at least 24 hours in
development before repeating the procedure with the production context:

```sh
kubectl --context "$CONTEXT" -n ambassador get pods \
  -l app.kubernetes.io/name=ambassador -o wide
kubectl --context "$CONTEXT" -n ambassador get events \
  --field-selector type=Warning --sort-by=.lastTimestamp
```

For rollback, repeat the patch with the recorded original probe settings. The
settings reported in #343 are `timeoutSeconds: 1`, `periodSeconds: 3`, and
`failureThreshold: 3` for both probes. The patch triggers another rollout.
If the release still uses chart 6.5.9, recheck the probes after future Helm
upgrades because the chart cannot preserve the timeout through its values.

### Adding authentication using basic auth

* There is a file to produce the required yaml, `produce_yaml_from_pw.py` that will give you a base64-ed value which is an admin username and requires a supplied password
* Once given, you can take this base64 value and use `ansible-vault` or `sealed-secrets` to seal it, so it can be used in the cluster.
  * For ansible-vault for dev, for example, do `ansible-vault encrypt dev-values.enc --vault-password-file password_file` to encrypt a new file

#### Notes
1. You can view the relevant contexts using kubectl config view | grep treetracker 2-4 can be done using ./monitoring/doctl_setup.sh CLUSTER_NAME, e.g. ./monitoring/doctl_setup.sh do-sfo2-dev-k8s-treetracker
