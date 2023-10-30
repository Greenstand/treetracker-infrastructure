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


