# What is Knative?

A way to deploy FaaS objects into Kubernetes

## How to get started

Install the CLI

```bash
brew tap knative-sandbox/kn-plugins
brew install func
```

To deploy a Knative function, use a yaml like the following:

```yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: hello
spec:
  template:
    spec:
      containers:
        - image: ghcr.io/knative/helloworld-go:latest # Container to be used
          ports:
            - containerPort: 8080
          env:
            - name: TARGET # Env vars
              value: "World"
```

The lifecycle of building and deploying the image used as the service
is described [here](https://knative.dev/docs/getting-started/create-a-function/)

e.g. the following will create a folder with a python function in it

```bash
func create -l python hello
```
