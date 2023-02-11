### How install Airflow into Kubernetes cluster
Greenstand uses Airflow as its main workflow orchestration tool. The main Airflow repo is here:

https://github.com/Greenstand/treetracker-airflow-dags

Greenstand has a dev and prod Kubernetes cluster running on DigitalOcean. dev / prod Airflow is installed on these Kubernetes clusters using a Helm Chart and configured using Ansible. You can read up on these technologies here:
- https://www.digitalocean.com/
- https://kubernetes.io/
- https://helm.sh/
- https://www.ansible.com/

The main Ansible playbook to configure Airflow is here:

https://github.com/Greenstand/treetracker-infrastructure/blob/master/airflow/roles/airflow/tasks/main.yml

To modify the Airflow installation, please see the steps below.

#### Install tools
The below instructions are for macOS:
1. Install doctl https://docs.digitalocean.com/reference/doctl/how-to/install/
- `brew install doctl`
2. Install helm 3
- `brew install helm`
3. Install ansible
- `sudo pip install --user ansible`
- `ansible-galaxy collection install community.kubernetes`

To access the dev Kubernetes cluster UI, first get an access token to the dev Kubernetes cluster by asking in the Greenstand automations-working-group Slack channel. Then:
- `doctl auth init --context dev-k8s-treetracker`
- `doctl auth list`
- `doctl auth switch --context dev-k8s-treetracker`
- `doctl auth list`

To access the dev Kubernetes cluster UI:
https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/
- `kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml`
- `kubectl proxy`

You can now go to
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/login
- input the access token to log in
- Don't forget to change the namespace to airflow in the UI

#### Connect and install helm chart using ansible
1. Use `doctl auth init` and pass your access token if you haven't already
2. Save the kubeconfig relevant to the cluster, e.g. `doctl kubernetes cluster kubeconfig save dev-k8s-treetracker`
- Switch to the context if not already switched, e.g. `kubectl config set-context do-sfo2-dev-k8s-treetracker --namespace=airflow` 
3. Run ansible to install helm chart `ansible-playbook airflow-playbook.yml -i environments/development`. Note the specific environment you are running against. In this particular command, you are running against the **development** environment.
- This instruction deploys any changes the airflow-web, airflow-worker, airflow-sync-user, etc. pods on the (dev) k8s cluster

#### Notes
1. You can view the relevant contexts using kubectl config view | grep treetracker 2-4 can be done using ./monitoring/doctl_setup.sh CLUSTER_NAME, e.g. ./monitoring/doctl_setup.sh do-sfo2-dev-k8s-treetracker
2. To add new users & passwords to the Airflow installations, please see:
https://github.com/Greenstand/treetracker-airflow-dags/issues/92
This is a good introduction to Secrets & SealedSecrets on Kubernetes and how to deploy them to Kubernetes using Ansible playbooks.