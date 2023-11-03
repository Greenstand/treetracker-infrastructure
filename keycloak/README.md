# The script to deploy Keycloak on Greenstand Kubernetes cluster

## Prerequisites

- Node.js
- kubeclt ? 

### To install prerequisites 

```bash
# install ansible
pip3 install ansible

# install k8s plugin
ansible-galaxy collection install community.kubernetes
```

## Usage

```bash
chmod +x deploy.sh
./deploy.sh
```


# Troubleshooting

## Error: "changesets check sum: Validation Failed"

This is because of the table: `databasechangelog` in the database, can be solved by cleaning up the whole schema tables.;
