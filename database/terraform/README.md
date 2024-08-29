# How to update db

Currently, just prod db postgresql cluster is under the control of terraform.

To update the Digital Ocean managed db:

1. Set up the token to access the DO object storage which is used as the backend for the terraform state. 

```bash
source setup_keys.sh
```

2. Run the terraform script to update the db.

```bash
terraform init
terraform plan
terraform apply
```


