
variable "cluster_name" {}

resource "digitalocean_kubernetes_cluster" "kubernetes-cluster" {
  name   = var.cluster_name
  region = "nyc1"
  # Grab the latest version slug from `doctl kubernetes options versions`
  version = "1.19.3-do.3"

  node_pool {
    name       = "default-node-pool"
    size       = "s-2vcpu-2gb"
    node_count = 3
    tags       = ["default-node"]
  }

}

resource "digitalocean_kubernetes_node_pool" "cloud-services-node-pool" {
  cluster_id =  digitalocean_kubernetes_cluster.kubernetes-cluster.id

  name       = "cloud-services-node-pool"
  size       = "s-2vcpu-2gb"
  node_count = 3
  tags       = ["cloud-services-node"]

}

