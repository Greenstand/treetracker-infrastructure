#!/bin/sh

terraform apply -var-file prod.env.tfvars
