module "knative" {
  source       = "../knative_k8s"
  cluster_name = "test-k8s-treetracker"
}
