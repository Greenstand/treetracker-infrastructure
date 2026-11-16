# CKAN Deployment

This directory contains the Ansible playbook and Kubernetes resources used to deploy CKAN to Greenstand Kubernetes clusters.

## Prerequisites

- Authorized Greenstand DigitalOcean Kubernetes access.
- doctl, kubectl, and Helm 3.
- Ansible with the kubernetes.core collection.
- Python dependencies: kubernetes, PyYAML, and jsonpatch.
- Authorized Ansible Vault password.

## Configure cluster access

Follow the [Scripts README](../scripts/README.md).
Run the cluster setup command from the repository root:

Example:

```bash
./scripts/doctl_setup.sh dev-k8s-treetracker
```

## Deploy CKAN

From this directory, run:

```bash
ANSIBLE_CONFIG="$PWD/ansible.cfg" ansible-playbook ckan-playbook.yml -e @dev-values.enc --vault-password-file /path/to/authorized/password_file
```

Replace the password-file placeholder with the authorized Vault password file path.

## Verify deployment

```bash
kubectl get pods -n ckan
kubectl get services -n ckan
helm list -n ckan
```

## Important

This configuration uses an external database and Greenstand-specific DigitalOcean node affinity. Review environment-specific settings before deployment. Do not deploy it to a local Kind cluster.
