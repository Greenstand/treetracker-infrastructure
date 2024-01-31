module "openfaas" {
  source       = "../faas-netes-chart"
  cluster_name = "prod-k8s-treetracker"
}
