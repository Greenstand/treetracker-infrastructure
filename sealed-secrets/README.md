# What are Sealed Secrets?
Sealed secrets allow for developers to commit an encrypted version of their secrets to source control. The pre-requisite is to have the SealedSecret CRD and controller installed in the Kubernetes cluster. A client utility tool called Kubeseal is used to communicate with the controller to encrypt the secret and create a SealedSecret resource that can be committed to source control.

A SealedSecret CRD will have a link to a Secret so if a SealedSecret resource is updated/deleted, the corresponding Secret will be updated/deleted accordingly. Therefore operations should be performed on the SealedSecret CRD rather than on a Secret.

## Official Documentation
https://github.com/bitnami-labs/sealed-secrets
# Installing Sealed Secret Operator & Kubeseal

## Install doctl(digital ocean cli tool)

- Install doctl command-line tool if you haven't already [install doctl](https://www.digitalocean.com/docs/apis-clis/doctl/how-to/install/)

You need digital ocean token from Greenstand Engineering team for setting up doctl before proceeding to the next step.

- Execute `doctl auth init`
The above command prompts for API token, the one you got from Greenstand Infrastructure team.

## Set up kubectl to connect to k8 clusters.

Install kubectl on your machine if you don't have done already. Install a kubectl version compatible with your Kubernetes cluster. The kubectl client should be within one minor version of the Kubernetes control plane.

Follow the official installation instructions:
https://kubernetes.io/docs/tasks/tools/

Execute the following to save the kubeconfig relevant to the cluster so that kubectl is able to connect, for e.g. for dev cluster

`doctl kubernetes cluster kubeconfig save dev-k8s-treetracker`

`kubectl config set-context do-sfo2-dev-k8s-treetracker`

## Sealed Secret CRD & Controller

The Sealed Secrets CRD and controller must already be installed in the Kubernetes cluster.

**Important:** The previous v0.13.1 controller installation manifest is obsolete and must not be applied to the production cluster. Refer to the official release documentation for supported installation and upgrade instructions.

## Kubeseal

The Kubeseal client version should match the Sealed Secrets controller version.

### Mac

Install Kubeseal using Homebrew:

```bash
brew install kubeseal
kubeseal --version
```
### Linux

Install Kubeseal v0.41.2:

```bash
curl -OL "https://github.com/bitnami/sealed-secrets/releases/download/v0.41.2/kubeseal-0.41.2-linux-amd64.tar.gz"

tar -xvzf kubeseal-0.41.2-linux-amd64.tar.gz kubeseal

sudo install -m 755 kubeseal /usr/local/bin/kubeseal

kubeseal --version
```

## Official Documentation

https://github.com/bitnami/sealed-secrets
https://github.com/bitnami/sealed-secrets/releases

# Usage: Creating Sealed Secrets With Kubeseal

## Using our script:

Run scripts/create-secret.sh to perform an interactive, automated sealed secret creation routine.  You will need kubectl access to the k8s cluster to successfully run this script.

## Manually:
export NAMESPACE="development"
export RESOURCE_NAME="treetracker-example-secret"
export KEY_NAME="example-key"
export SECRET="replace-with-your-secret-value"
### 1. Creating a temporary k8s secret to be encrypted
`echo -n $SECRET | kubectl -n $NAMESPACE create secret generic $RESOURCE_NAME --dry-run=client --from-file=$KEY_NAME=/dev/stdin -o yaml >treetracker-new-secret.yaml`

This will create a new file called **treetracker-new-secret.yaml** that will be used as input to Kubeseal.

Remove any unnecessary metadata such as **creation timestamp, namespace**.
### 2. Using Kubeseal to create a SealedSecret resource
`kubeseal -n $NAMESPACE -o yaml <treetracker-new-secret.yaml >treetracker-sealed-secret.yaml`

This will create a new file called **treetracker-sealed-secret.yaml** that can be safely committed to source control.

Remove any unnecessary metadata such as **creation timestamp, namespace**.

### 3. Deploy newly created SealedSecret
`kubectl -n $NAMESPACE create -f treetracker-sealed-secret.yaml`

You will now see a SealedSecret resource along with a Secret resource created.
You can verify the created resource by using the following command:

`kubectl -n $NAMESPACE get sealedsecrets`


## Official Documentation
https://github.com/bitnami-labs/sealed-secrets#usage
