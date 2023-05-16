module "solr" {
  source       = "../solr_chart"
  cluster_name = "dev-k8s-treetracker"
}
