variable "cluster_name" {}
variable  "bucket_name" {}
variable  "key_name"{}

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

