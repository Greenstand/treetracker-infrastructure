module "prod-web-map" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite?ref=acm_removed"
  domain = "webmap.treetracker.org"
  error_document = "index.html"
}
