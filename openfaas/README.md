# What is OpenFaaS/ faas-netes?

A way to deploy FaaS objects into Kubernetes that follows open standards.

## How to get started

Install the CLI

```bash
brew install faas-cli
```

Then to download templates use

```bash
faas-cli template pull
```

Then to create a sample one in Python, use

```bash
faas-cli new hello-world --lang python3
```

Edit the `hello-world.yml` file to have the right image tag/location,
and update `requirements.txt` as necessary.

Then get the secret to log in, and port-forward the gateway

```bash
kubectl port-forward -n openfaas svc/gateway 8080:8080
PASSWORD=$(kubectl -n openfaas get secret basic-auth -o jsonpath="{.data.basic-auth-password}" | base64 --decode)
faas-cli login --password $PASSWORD
```

Lastly, build, push and deploy your function with the following
(assuming you have dockerhub push access set up)

```bash
faas-cli build --yaml hello-world.yml
faas-cli publish --yaml hello-world.yml --reset-qemu=false # For ARM -> AMD64
faas-cli deploy --yaml hello-world.yml
```
