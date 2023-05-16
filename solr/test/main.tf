module "solr" {
  source       = "../solr_chart"
  cluster_name = "test-k8s-treetracker"
}
