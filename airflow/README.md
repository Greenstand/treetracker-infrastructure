### How install into kubernetes cluster

#### Install tools
1. Install doctl, brew install doctl on mac
1. Install helm 3 if not present, brew install helm on mac
1. Install ansible if not present

#### Connect and install helm chart using ansible
1. Use `doctl auth init` and pass your DO API key
1. Save the kubeconfig relevant to the cluster, e.g. `doctl kubernetes cluster kubeconfig save dev-k8s-treetracker`
    1. Switch to the context if not already switched, e.g. kubectl config set-context do-sfo2-dev-k8s-treetracker 
1. Run ansible to install helm chart `ansible-playbook airflow-playbook.yml -i environments/development`. Note the specific environment you are running against. In this particular command, you are running against the **development** environment.


#### Notes
1. You can view the relevant contexts using kubectl config view | grep treetracker 2-4 can be done using ./monitoring/doctl_setup.sh CLUSTER_NAME, e.g. ./monitoring/doctl_setup.sh do-sfo2-dev-k8s-treetracker
