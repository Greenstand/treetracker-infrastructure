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


## Expose user creation time in the Raw Client

The Raw Client displays the user's account creation time from the
`createdTimestamp` claim in the Keycloak access token.

The `raw-client` client must have a User Property protocol mapper
configured in the `treetracker` realm.

### Configure the protocol mapper

In the Keycloak Admin Console:

1. Select the `treetracker` realm.
2. Open **Clients** and select `raw-client`.
3. Open its dedicated client scope under **Client scopes**.
4. Add a mapper using **By configuration** > **User Property**.
5. Configure the mapper with these values:

| Setting | Value |
| --- | --- |
| Name | User Created Timestamp |
| User Property | `createdTimestamp` |
| Token Claim Name | `createdTimestamp` |
| Claim JSON Type | `long` |
| Add to access token | On |
| Add to ID token | Off |

6. Save the mapper.

The `createdTimestamp` value is a Unix timestamp in milliseconds.
The Raw Client converts it to the browser's local date and time.

If the claim is missing or invalid, the Raw Client displays
`Not available`. Existing users may have no creation timestamp if
their records predate the introduction of this Keycloak property.

This mapper configuration must be applied by a Keycloak realm
administrator. It is not automatically created by the Kubernetes
deployment in this repository.

# Troubleshooting

## Error: "changesets check sum: Validation Failed"

This is because of the table: `databasechangelog` in the database, can be solved by cleaning up the whole schema tables.;
