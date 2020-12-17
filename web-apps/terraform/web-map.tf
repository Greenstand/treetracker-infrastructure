module "staticwebsite" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite?ref=with_cert"
  domain = "dev.webmap.treetracker.org"
  error_document = "index.html"
}
