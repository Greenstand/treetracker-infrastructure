# Prerequisites

- Ensure you have `tfenv` installed in your system. https://github.com/tfutils/tfenv

- The terraform configuration in this directory requires to have `terraform` binary version to be minimum 1.4.6 Ref: https://developer.hashicorp.com/terraform/tutorials/configuration-language/versions#review-example-configuration

  



# How to set up terraform

Find your digitalocean spaces access key and secret key here: https://cloud.digitalocean.com/account/api/spaces?i=d79377

Save it to your local `~/.netrc` file:

```bash
echo "machine sfo2.digitaloceanspaces.com login $SPACES_KEY password $SPACES_SECRET" >> ~/.netrc
```

Go the env folder, load key

```bash
cd dev
source setup_keys.sh
```

# How to run terraform

Use correct version:
```bash
tfenv use min-required
```
OR 
```bash
tfenv use # this will configure the correct version from .terraform-version file
```

```bash
terraform version # check if the version matches with the required_version in provider.tf
```

Init:

```bash
terraform init -backend-config=backend-config.tfvars
```

Plan, in the prompt input the database password:

```bash
terraform plan -var-file=dev.env.tfvars
```

Apply:

```bash
terraform apply -var-file=dev.env.tfvars
```

# About the `extra` folder

Put increased grant here, don't put them in the main folder because the order 
matters, if you put them in the main folder, they will be applied before the
schema is created, which will cause error.

# Troubleshooting

## Error: role or object does not exist

When applying a new schema/grant, sometimes error reports xxx does not exist. But if you run it again, it works. Known issue [here](https://github.com/Greenstand/treetracker-infrastructure/issues/201)

