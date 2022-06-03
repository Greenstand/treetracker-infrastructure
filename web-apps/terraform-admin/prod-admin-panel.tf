module "prod-admin-panel" {
  source         = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain         = "admin.treetracker.org"
  error_document = "index.html"
}
