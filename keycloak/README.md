# The script to deploy Keycloak on Greenstand Kubernetes cluster

## Prerequisites

- Node.js
- kubectl ? 

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


## Local backup and restore test

See [Keycloak PostgreSQL backup and restore test](docs/backup-restore-test.md)
for a local Docker exercise related to issue #160.

The guide records a successful schema restore and fresh user and administrator
logins with Keycloak 23.0.0 and PostgreSQL 14. It does not validate recovery of
Greenstand's deployed environments.
