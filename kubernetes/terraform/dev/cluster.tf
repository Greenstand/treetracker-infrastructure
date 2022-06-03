variable "cluster_name" {}

data "digitalocean_kubernetes_versions" "treetracker_kubernetes_version" {
  version_prefix = "1.20."
}

resource "digitalocean_kubernetes_cluster" "kubernetes-cluster" {
  name = var.cluster_name

  lifecycle {
    prevent_destroy = true
  }

  region       = "sfo2"
  auto_upgrade = true
  version      = data.digitalocean_kubernetes_versions.treetracker_kubernetes_version.latest_version

  node_pool {
    name       = "default-node-pool"
    size       = "s-2vcpu-4gb"
    node_count = 1
    tags       = ["default-node", "treetracker-database-access"]
  }

}

resource "digitalocean_kubernetes_node_pool" "microservices-node-pool" {
  cluster_id = digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "microservices-node-pool"
  size       = "s-2vcpu-4gb"
  node_count = 3
  tags       = ["microservices-node", "treetracker-database-access"]

}


resource "digitalocean_kubernetes_node_pool" "cloud-services-node-pool" {
  cluster_id = digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "cloud-services-node-pool"
  size       = "s-2vcpu-4gb"
  node_count = 4
  tags       = ["cloud-services-node", "treetracker-database-access"]

}

resource "digitalocean_kubernetes_node_pool" "monitoring-node-pool" {
  cluster_id = digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "monitoring-node-pool"
  size       = "s-2vcpu-4gb"
  node_count = 3
  tags       = ["monitoring-node", "treetracker-database-access"]

}
