
data "digitalocean_kubernetes_versions" "treetracker_kubernetes_version" {
  version_prefix = "1.19."
}

resource "digitalocean_kubernetes_cluster" "kubernetes-cluster" {
  name   = var.cluster_name

  lifecycle {
    prevent_destroy = true
  }

  region = var.do_region # "nyc1"
  auto_upgrade = true
  version      = data.digitalocean_kubernetes_versions.treetracker_kubernetes_version.latest_version

  node_pool {
    name       = "default-node-pool"
    size       = "s-2vcpu-2gb"
    node_count = 1
    tags       = ["microservices-node", "treetracker-database-access"]
  }

}

resource "digitalocean_kubernetes_node_pool" "microservices-node-pool" {
  cluster_id =  digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "microservices-node-pool"
  size       = "s-2vcpu-4gb"
  node_count = 3
  tags       = ["microservices-node", "treetracker-database-access"]

}

resource "digitalocean_kubernetes_node_pool" "cloud-services-node-pool" {
  cluster_id =  digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "cloud-services-node-pool"
  size       = "s-2vcpu-4gb"
  node_count = 5
  tags       = ["cloud-services-node", "treetracker-database-access"]

}

resource "digitalocean_kubernetes_node_pool" "monitoring-node-pool" {
  cluster_id =  digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "monitoring-node-pool"
  size       = "s-4vcpu-8gb"
  node_count = 3
  tags       = ["monitoring-node", "treetracker-database-access"]

}

