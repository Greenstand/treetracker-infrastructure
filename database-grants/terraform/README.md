# Prerequisites

- Terraform 1.4.6 , please stick to this version for now, tested 1.6.x, it brings issue with the Dititalocean storage as backend


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

# Troubleshooting

## Error: role or object does not exist

When applying a new schema/grant, sometimes error reports xxx does not exist. But if you run it again, it works. Known issue [here](https://github.com/Greenstand/treetracker-infrastructure/issues/201)
