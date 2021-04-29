variable "cluster_name" {}

data "digitalocean_kubernetes_versions" "treetracker_kubernetes_version" {
  version_prefix = "1.19."
}

resource "digitalocean_kubernetes_cluster" "kubernetes-cluster" {
  name   = var.cluster_name
  region = "nyc1"
  auto_upgrade = true
  version      = data.digitalocean_kubernetes_versions.treetracker_kubernetes_version.latest_version


  node_pool {
    name       = "default-node-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
    tags       = ["default-node", "treetracker-database-access"]
  }

}

resource "digitalocean_kubernetes_node_pool" "cloud-services-node-pool" {
  cluster_id =  digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "cloud-services-node-pool"
  size       = "s-2vcpu-4gb"
  node_count = 3
  tags       = ["cloud-services-node", "treetracker-database-access"]

}

terraform {
  # DigitalOcean uses the S3 spec.
  backend "s3" {
    bucket = "treetracker-dev-terraform"
    key    = "treetracker-dev-terrraform.tfstate"
    endpoint = "https://sfo2.digitaloceanspaces.com"
    # DO uses the S3 format
    # eu-west-1 is used to pass TF validation
    # Region is ACTUALLY sfo2 on DO
    region = "eu-west-1"
    access_key = "MW6EIXVN5BMVYDLK4DE4"
    secret_key = "aISjzjh5qZQTfL92dsLUPMDXJfYqaEzCt6WMKhQc+ew"

    # Deactivate a few checks as TF will attempt these against AWS
    skip_credentials_validation = true
    # skip_get_ec2_platforms = true
    # skip_requesting_account_id = true
    skip_metadata_api_check = true
  }
}