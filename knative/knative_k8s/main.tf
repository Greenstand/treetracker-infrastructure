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

provider "kubectl" {
  host  = data.digitalocean_kubernetes_cluster.dev.endpoint
  token = data.digitalocean_kubernetes_cluster.dev.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.dev.kube_config[0].cluster_ca_certificate
  )
}

data "http" "knative_operator_yaml" {
  url = "https://github.com/knative/operator/releases/download/knative-v1.10.2/operator.yaml"

  # Optional request headers
  request_headers = {
    Accept = "application/yaml"
  }
}

data "kubectl_file_documents" "docs" {
  content = tostring(data.http.knative_operator_yaml.body)
}

resource "kubectl_manifest" "knative_operator" {
  for_each  = data.kubectl_file_documents.docs.manifests
  yaml_body = each.value
}

data "kubectl_file_documents" "serving_docs" {
  content = file("${path.module}/knative_serving.yaml")
}

resource "kubectl_manifest" "knative_serving" {
  for_each  = data.kubectl_file_documents.serving_docs.manifests
  yaml_body = each.value
}



data "kubectl_file_documents" "eventing_docs" {
  content = file("${path.module}/knative_eventing.yaml")
}

resource "kubectl_manifest" "knative_eventing" {
  for_each  = data.kubectl_file_documents.eventing_docs.manifests
  yaml_body = each.value
}
