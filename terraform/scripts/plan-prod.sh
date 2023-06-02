#!/bin/sh

terraform plan -var-file prod.env.tfvars
