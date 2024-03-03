#!/bin/bash

# Retrieve keys from your netrc, specified as
# machine sfo2.digitaloceanspaces.com login KEY password SECRET
# Source this file before running terraform commands

grep_string=$(cat backend.tf | grep endpoint | awk -F'=' '{print $2}' | awk -F'/' '{print $NF}' | sed 's/"//g')

netrc_string=$(grep ${grep_string} ~/.netrc)
export AWS_ACCESS_KEY_ID=$(echo $netrc_string | awk '{print $4}')
export AWS_SECRET_ACCESS_KEY=$(echo $netrc_string | awk '{print $6}')
