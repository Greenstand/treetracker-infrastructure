# What are Sealed Secrets?
Sealed secrets allow for developers to commit an encrypted version of their secrets to source control. The pre-requisite is to have the SealedSecret CRD and controller installed in the Kubernetes cluster. A client utility tool called Kubeseal is used to communicate with the controller to encrypt the secret and create a SealedSecret resource that can be committed to source control.

A SealedSecret CRD will have a link to a Secret so if a SealedSecret resource is updated/deleted, the corresponding Secret will be updated/deleted accordingly. Therefore operations should be performed on the SealedSecret CRD rather than on a Secret.

Official documentation can be found at https://github.com/bitnami-labs/sealed-secrets.
# Installing Sealed Secret Operator & Kubeseal
## Sealed Secret CRD & Controller
`kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.13.1/controller.yaml`

## Kubeseal
### Mac
`brew install kubeseal`
### Linux
`wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.13.1/kubeseal-linux-amd64 -O kubeseal`

`sudo install -m 755 kubeseal /usr/local/bin/kubeseal`

## Official Documentation
https://github.com/bitnami-labs/sealed-secrets#installation
https://github.com/bitnami-labs/sealed-secrets/releases


# Usage: Creating Sealed Secrets With Kubeseal
## 1. Creating a temporary k8s secret to be encrypted
`echo -n TEST | kubectl -n development create secret generic treetracker-test-secret --dry-run=client --from-file=jwt=/dev/stdin -o yaml >treetracker-test-secret.yaml`

This will create a new file called **treetracker-test-secret.yaml** that will be used as input to Kubeseal.

Remove any unnecessary metadata such as **creation timestamp, namespace**.
## 2. Using Kubeseal to create a SealedSecret resource
`kubeseal -n development -o yaml <treetracker-test-secret.yaml >treetracker-sealed-secret.yaml`

This will create a new file called **treetracker-sealed-secret.yaml** that can be safely committed to source control.

Remove any unnecessary metadata such as **creation timestamp, namespace**.

## 3. Deploy newly created SealedSecret
`kubectl -n development create -f treetracker-sealed-secret.yaml`

You will now see a SealedSecret resource along with a Secret resource created.

## Official Documentation
https://github.com/bitnami-labs/sealed-secrets#usage