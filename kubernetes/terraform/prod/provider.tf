variable "do_token" {}
provider "digitalocean" {
  token = var.do_token
}
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "1.25.2"
    }

  }
}
#data "digitalocean_kubernetes_cluster" "kubernetes-cluster" {
#  name = "dev-k8s-treetracker"
#}

provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.kubernetes-cluster.endpoint
  token = data.digitalocean_kubernetes_cluster.kubernetes-cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.kuberntes-cluster.kube_config[0].cluster_ca_certificate
  )
}
