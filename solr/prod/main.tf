module "solr" {
  source       = "../solr_chart"
  cluster_name = "prod-k8s-treetracker"
}
