## Welcome to Treetracker Infrastructure

### Greenstand's Current Architecture

There are two ways most applications are deployed. The majority of our applications run currently on digital ocean droplets. New applications are being run on Digital Ocean's Managed Kubernetes.

#### The Current Setup

There is a managed postgresql database that most of our tree data is backed by.

Tree images are uploaded to Digital Ocean's spaces. The various backend APIs are hosted on a handful of Digital Ocean droplets.

### The Application Platform

The goal of the application platform is to have a relatively homogeneous set of services, i.e. services that are all:
* Deployed into the DO Managed Kubernetes clusters via [kustomize](https://kustomize.io/)
* Kubeseal for secrets
* Have roughly the same setup as far as how they are deployed/monitored/reached

For how services are reached (i.e. ingress)
* A reverse proxy exists for our services controlled by [Ambassador](https://www.getambassador.io/)
* DNS is set with terraform in our Digital Ocean account

For how our services are monitored, monitoring is split among three pieces
* Prometheus + Grafana for metrics
* Jaeger for traces
* Elasticsearch + Kibana for logs

#### A little more detail: why Kubernetes and what is it?

Kubernetes is the open source version of Google's container management infrastructure. It allows us to monitor services in a more generic/ cleaner way, and also deal with scaling and lifecycle issues at a level above the application. It also means we don't have to manage our own boxes (i.e. our own Digital Ocean droplets).

### Support or Contact

Want to reach out to the team? Come hit us up on our [slack channel](https://app.slack.com/client/T6WR1QS8J/CH79F6W8G)
