data "digitalocean_kubernetes_cluster" "dev" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes {
    host  = data.digitalocean_kubernetes_cluster.dev.endpoint
    token = data.digitalocean_kubernetes_cluster.dev.kube_config[0].token
    cluster_ca_certificate = base64decode(
      data.digitalocean_kubernetes_cluster.dev.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "helm_release" "solr" {
  name             = "solr-operator"
  repository       = "https://solr.apache.org/charts"
  chart            = "solr-operator"
  version          = "0.7.0"
  namespace        = "solr"
  create_namespace = true


  values = [
    "${file("${path.module}/values.yaml")}",
    var.values_file
  ]

}
