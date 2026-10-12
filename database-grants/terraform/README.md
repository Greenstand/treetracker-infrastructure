# Prerequisites

- Install [tfenv](https://github.com/tfutils/tfenv).
- The dev, test, and prod configurations require Terraform `~> 1.4.6`: version 1.4.6 or later within the 1.4.x series. Terraform 1.5.0 and later are not accepted.
- The test and prod directories include `.terraform-version` files selecting Terraform 1.4.6 for tfenv.
- Before using this version against an existing test or prod backend, confirm compatibility with the current state and the version used by maintainers.

Reference: [Terraform version constraints](https://developer.hashicorp.com/terraform/language/expressions/version-constraints).

# How to set up Terraform

Find your DigitalOcean Spaces access key and secret key here:
https://cloud.digitalocean.com/account/api/spaces

Save them to your local `~/.netrc` file:

```bash
echo "machine sfo2.digitaloceanspaces.com login $SPACES_KEY password $SPACES_SECRET" >> ~/.netrc
```

The examples below use the dev environment. For test or prod, use the corresponding environment directory and variable file.

Go to the environment directory and load the keys:

```bash
cd dev
source setup_keys.sh
```

# How to run Terraform

Select Terraform from the environment directory.

For test and prod, install and select the version from the committed `.terraform-version` file:

```bash
tfenv install
tfenv use
terraform version
```

For dev, which does not currently include a `.terraform-version` file:

```bash
tfenv install 1.4.6
tfenv use 1.4.6
terraform version
```

The selected version must satisfy `required_version` in `provider.tf`.

The test environment's `provider.tf` is a symbolic link to `../prod/provider.tf`, so both environments share the same Terraform version constraint.

Initialize the backend:

```bash
terraform init -backend-config=backend-config.tfvars
```

Review the plan, providing the database password when prompted:

```bash
terraform plan -var-file=dev.env.tfvars
```

Apply after reviewing and approving the plan:

```bash
terraform apply -var-file=dev.env.tfvars
```

# About the `extra` folder

Put additional grants here rather than in the main folder. Creation order matters: grants must be applied after the corresponding schema exists.

# Troubleshooting

## Error: role or object does not exist

When applying a new schema or grant, Terraform may report that a role or object does not exist. A subsequent run has sometimes succeeded.

See the [known issue](https://github.com/Greenstand/treetracker-infrastructure/issues/201). Inspect the failure and review a fresh plan before retrying.
