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

#### Connect and install help chart using ansible
1. Use `doctl auth init` and pass your DO API key
1. Save the kubeconfig relevant to the cluster, e.g. `doctl kubernetes cluster kubeconfig save dev-k8s-treetracker`
    1. Switch to the context if not already switched, e.g. kubectl config set-context do-sfo2-dev-k8s-treetracker 
    1. You can view the relevant contexts using kubectl config view | grep treetracker 2-4 can be done using ./monitoring/doctl_setup.sh CLUSTER_NAME, e.g. ./monitoring/doctl_setup.sh do-sfo2-dev-k8s-treetracker
1. Run ansible to install ambassador helm chart `ansible-playbook ambassador-playbook.yml`
1. Ambassdor is deployed! 

### Adding monitoring to Prometheus
Once Ambassador has been installed, we need to expose the /metrics path so that Prometheus can scrape metrics. We do this by creating a ServiceMonitor resource in the same namespace that Ambassador is running it. This tells Prometheus how to collect metrics from Ambassador. There is already a ServiceMonitor manifest file in this repo that can be used.

`kubectl -n ambassador apply -f ambassador-service-monitor.yaml`
