module "knative" {
  source       = "../knative_k8s"
  cluster_name = "dev-k8s-treetracker"
}
