module "openfaas" {
  source       = "../faas-netes-chart"
  cluster_name = "dev-k8s-treetracker"
}
