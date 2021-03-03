module "staticwebsite" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite?ref=acm_removed"
  domain = "dev.webmap.treetracker.org"
  error_document = "index.html"
}
