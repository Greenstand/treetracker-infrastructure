#!/bin/sh

terraform import -var-file=dev.env.tfvars digitalocean_kubernetes_cluster.kubernetes-cluster a949ce4d-8fdd-402b-82c1-a38e47deb4cc
