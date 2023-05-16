## Running this terrform
1. install terraform `brew install terraform`
1. set up access to s3/spaces
  1. create access key in control panel, note key id and access key
  2. update ~/.netrc to hold access like with a line like `machine sfo2.digitaloceanspaces.com login KEY_ID password ACCESS_KEY`
1. load keys by running `source setup_keys.sh`
1. `terraform init` get ready to run terraform
1. `terraform plan` to see changes that will be applied
1. `terraform apply` to apply those changes
