#!/bin/bash

# Retrieve keys from your netrc. Two entries are expected:
#   machine sfo2.digitaloceanspaces.com login SPACES_KEY password SPACES_SECRET
#   machine api.digitalocean.com login unused password DO_API_TOKEN
# Source this file before running terraform commands
spaces_string=$(grep sfo2.digitaloceanspaces.com ~/.netrc)
export AWS_ACCESS_KEY_ID=$(echo $spaces_string | awk '{print $4}')
export AWS_SECRET_ACCESS_KEY=$(echo $spaces_string | awk '{print $6}')

api_string=$(grep api.digitalocean.com ~/.netrc)
export TF_VAR_do_token=$(echo $api_string | awk '{print $6}')

