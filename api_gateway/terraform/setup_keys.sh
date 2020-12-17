#!/bin/bash

# Retrieve keys from your netrc, specified as
# machine sfo2.digitaloceanspaces.com login KEY password SECRET
# Source this file before running terraform commands
netrc_string=$(grep sfo2.digitaloceanspaces.com ~/.netrc)
export AWS_ACCESS_KEY_ID=$(echo $netrc_string | awk '{print $4}')
export AWS_SECRET_ACCESS_KEY=$(echo $netrc_string | awk '{print $6}')

netrc_string=$(grep aws.treetracker.org ~/.netrc)
export TF_VAR_TREETRACKER_AWS_ACCESS_KEY_ID=$(echo $netrc_string | awk '{print $4}')
export TF_VAR_TREETRACKER_AWS_SECRET_ACCESS_KEY=$(echo $netrc_string | awk '{print $6}')
