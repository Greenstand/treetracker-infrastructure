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

locals {
  solr_version = "0.7.0"
}
resource "helm_release" "solr_operator" {
  name             = "solr-operator"
  repository       = "https://solr.apache.org/charts"
  chart            = "solr-operator"
  version          = local.solr_version
  namespace        = "solr"
  create_namespace = true


  values = [
    "${file("${path.module}/solr-operator-values.yaml")}",
    var.solr_operator_values_file
  ]

}


resource "helm_release" "solr" {
  name             = "solr"
  repository       = "https://solr.apache.org/charts"
  chart            = "solr"
  version          = local.solr_version
  namespace        = "solr"
  create_namespace = true


  values = [
    "${file("${path.module}/solr-values.yaml")}",
    var.solr_values_file
  ]

}
