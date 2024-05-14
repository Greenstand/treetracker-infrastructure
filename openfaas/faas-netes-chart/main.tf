data "digitalocean_kubernetes_cluster" "dev" {
  name = var.cluster_name
}


provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.dev.endpoint
  token = data.digitalocean_kubernetes_cluster.dev.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.dev.kube_config[0].cluster_ca_certificate
  )
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

resource "kubernetes_namespace" "openfaas-fn-ns" {
  metadata {
    name = "openfaas-fn"
    annotations = {
      "linkerd.io/inject"                     = "enabled"
      "config.linkerd.io/skip-inbound-ports"  = "4222"
      "config.linkerd.io/skip-outbound-ports" = "4222"
    }

    labels = {
      istio-injection = "enabled"
      role            = "openfaas-fn"
    }

  }
}

locals {
  chart_version = "13.0.0"
}


resource "helm_release" "openfaas_chart" {
  name             = "openfaas"
  repository       = "https://openfaas.github.io/faas-netes/"
  chart            = "openfaas"
  version          = local.chart_version
  namespace        = "openfaas"
  create_namespace = true


  values = [
    "${file("${path.module}/values.yaml")}",
    var.values_file
  ]

}

