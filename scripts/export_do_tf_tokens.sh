#!/usr/bin/env bash

my_env=${1:?Environment is required}
line=$(grep "digitalocean.${my_env}.treetracker.org" ~/.netrc)
export DIGITALOCEAN_TOKEN=$(echo $line | awk '{print $6}')

netrc_string=$(grep "sfo2.${my_env}.digitaloceanspaces.com" ~/.netrc)
export AWS_ACCESS_KEY_ID=$(echo $netrc_string | awk '{print $4}')
export AWS_SECRET_ACCESS_KEY=$(echo $netrc_string | awk '{print $6}')
