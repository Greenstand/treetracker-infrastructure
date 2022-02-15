# How to run Terraform for the monitor project

You'll need to first setup your keys:

1. Add your DO personal access key here:

```bash
echo "do_token = \"$DO_ACCESS_KEY\"" >monitoring/terraform/terraform.tfvars
```

1. Add the spaces key for the terraform state in your `~/.netrc`



```bash
echo "machine sfo2.digitaloceanspaces.com login $SPACES_KEY password $SPACES_SECRET
" >> ~/.netrc
```

1. `source setup_keys.sh` to put the keys into your shell

1. Run `terraform init` and `terraform plan` to verify everything is working alright
