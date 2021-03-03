module "test-web-map" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite?ref=acm_removed"
  domain = "test.webmap.treetracker.org"
  error_document = "index.html"
}
