# Knative RabbitMQ Source

Deploys the Knative RabbitMQ event source controller compatible with
Knative Eventing v1.23.0.

## Version

- Knative Eventing: v1.23.0
- Knative RabbitMQ Source: v1.23.0
- Release manifest: rabbitmq-source.yaml

The manifest is pinned to the official v1.23.0 release and uses immutable
SHA256 image digests.

## Prerequisites

- Knative Eventing v1.23.0 installed and healthy.
- cert-manager installed and healthy.
- RabbitMQ Cluster Operator installed.
- RabbitMQ Messaging Topology Operator installed.
- A reachable RabbitMQ broker.
- Cluster administrator permissions for CRDs, RBAC, and webhooks.

Coordinate installation with the cluster administrator. This controller
installation includes cluster-wide resources.

## Installation

Confirm the Kubernetes context before proceeding:

    kubectl config current-context

Install the release:

    kubectl apply -f knative/rabbitmq-source/rabbitmq-source.yaml

Wait for the deployments:

    kubectl rollout status deployment/rabbitmq-controller-manager \
      -n knative-sources --timeout=180s

    kubectl rollout status deployment/rabbitmq-webhook \
      -n knative-sources --timeout=180s

Verify:

    kubectl get crd rabbitmqsources.sources.knative.dev
    kubectl get pods -n knative-sources

## Creating a RabbitMQSource

RabbitMQSource resources are application-specific and must be managed
separately from this controller installation.

For an in-cluster RabbitMQ Cluster Operator broker, use its resource name
and namespace in rabbitmqClusterReference.

Example only:

    apiVersion: sources.knative.dev/v1alpha1
    kind: RabbitmqSource
    metadata:
      name: application-rabbitmq-source
      namespace: application-namespace
    spec:
      rabbitmqClusterReference:
        name: rabbitmqcluster-main
        namespace: rabbitmq-cluster
      rabbitmqResourcesConfig:
        predeclared: true
        queueName: application-queue
        vhost: /
        parallelism: 1
      sink:
        uri: http://application-sink.application-namespace.svc.cluster.local/

Replace the example queue, namespace, and sink with application-approved
values. Confirm queue permissions and vhost configuration with the
application owner.

## Local validation

The v1.23.0 controller was tested on a local Kind cluster with Knative
Eventing, RabbitMQ Cluster Operator, RabbitMQ Messaging Topology Operator,
a local RabbitMQ broker, and a local HTTP event receiver.

A test message was successfully published to RabbitMQ and delivered through
RabbitMQSource to the HTTP receiver.

The local broker, queue, publisher, and HTTP receiver are test resources,
not production configuration.

## Security

- Never commit generated Secrets, passwords, private keys, or certificates.
- Do not reuse local test credentials in shared environments.
- Follow the target cluster's approved secret and certificate management.
- Do not expose RabbitMQ AMQP or management ports publicly without approval.

## Upgrade and rollback

Review release notes and compatibility requirements before upgrading.
Coordinate changes with the Knative cluster administrator.

Before uninstalling, remove dependent RabbitMQSource resources and review
all cluster-wide resources in the release manifest. Do not blindly delete
shared Knative CRDs, webhooks, RBAC, or namespaces.
