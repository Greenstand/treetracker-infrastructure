provider "digitalocean" {
  token = var.do_token
}

provider "kubernetes" {
  host             = data.digitalocean_kubernetes_cluster.kubernetes-cluster.endpoint
  token            = data.digitalocean_kubernetes_cluster.kubernetes-cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.kuberntes-cluster.kube_config[0].cluster_ca_certificate
  )
}
