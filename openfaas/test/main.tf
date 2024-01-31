module "openfaas" {
  source       = "../faas-netes-chart"
  cluster_name = "test-k8s-treetracker"
}
