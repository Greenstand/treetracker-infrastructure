### What is Jaeger?

A distributed tracing system. For more info, look at [their site](https://www.jaegertracing.io/)

### How to deploy

Get logged into digital ocean using kubectl

### Setting Default CPU/Memory K8s Resources

Since this is a WIP in the upstream project (https://github.com/jaegertracing/jaeger-operator/issues/872) we have manually set the default k8s resources by simply using `kubectl edit deploy jaegar`.
