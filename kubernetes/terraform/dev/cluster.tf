variable "cluster_name" {}

resource "digitalocean_kubernetes_cluster" "kubernetes-cluster" {
  name = var.cluster_name

  lifecycle {
    prevent_destroy = true
  }

  region       = "sfo2"
  auto_upgrade = true
  version      = "1.32.13-do.2"

  node_pool {
    name       = "default-node-pool"
    size       = "s-2vcpu-4gb"
    auto_scale = true
    min_nodes  = 1
    max_nodes  = 2
    tags       = ["default-node", "treetracker-database-access"]
  }

}

resource "digitalocean_kubernetes_node_pool" "microservices-node-pool" {
  cluster_id = digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "microservices-node-pool"
  size       = "s-2vcpu-4gb"
  auto_scale = true
  min_nodes  = 1
  max_nodes  = 3
  tags       = ["microservices-node", "treetracker-database-access"]

}


resource "digitalocean_kubernetes_node_pool" "cloud-services-node-pool" {
  cluster_id = digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "cloud-services-node-pool"
  size       = "s-2vcpu-4gb"
  auto_scale = true
  min_nodes  = 1
  max_nodes  = 4
  tags       = ["cloud-services-node", "treetracker-database-access"]

}

resource "digitalocean_kubernetes_node_pool" "monitoring-node-pool" {
  cluster_id = digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "monitoring-node-pool"
  size       = "s-2vcpu-4gb"
  auto_scale = true
  min_nodes  = 0
  max_nodes  = 3
  tags       = ["monitoring-node", "treetracker-database-access"]

}
