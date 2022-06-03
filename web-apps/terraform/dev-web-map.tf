module "staticwebsite" {
  source         = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain         = "dev.webmap.treetracker.org"
  error_document = "index.html"
}
