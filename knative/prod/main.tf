module "knative" {
  source       = "../knative_k8s"
  cluster_name = "prod-k8s-treetracker"
}
