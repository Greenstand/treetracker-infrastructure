### Getting logged into the cluster

### How install into kubernetes cluster

#### Install tools
1. Install doctl, brew install doctl on mac

#### Connect and install help chart using ansible
1. Use `doctl auth init` and pass your DO API key
1. Save the kubeconfig relevant to the cluster, e.g. `doctl kubernetes cluster kubeconfig save dev-k8s-treetracker`
    1. Switch to the context if not already switched, e.g. kubectl config set-context do-sfo2-dev-k8s-treetracker 
    1. You can view the relevant contexts using kubectl config view | grep treetracker 2-4 can be done using ./monitoring/doctl_setup.sh CLUSTER_NAME, e.g. ./monitoring/doctl_setup.sh do-sfo2-dev-k8s-treetracker
1. Deploy RabbitMQ operator `kubectl apply -f "https://github.com/rabbitmq/cluster-operator/releases/latest/download/cluster-operator.yml"`
1. kubectl apply -f deployment/base/definition.yaml
1. Expose RabbitMQ metrics by deploying PodMonitor resource
`kubectl apply -f deployment/base/rabbitmq-pod-monitor.yaml`

#### Exposing RabbitMQ cluster for dev purposes
expose-service.yaml contains a resource for making rabbitmq available to devs working outside of the cluster.  This shouldn't be used in test or production.
