#!/bin/sh

# Retrieve keys from your netrc, specified as
# machine sfo2.digitaloceanspaces.com login KEY password SECRET
# Source this file before running terraform commands

netrc_string=$(grep aws.dev.treetracker.org ~/.netrc)
export AWS_ACCESS_KEY_ID=$(echo $netrc_string | awk '{print $4}')
export AWS_SECRET_ACCESS_KEY=$(echo $netrc_string | awk '{print $6}')
