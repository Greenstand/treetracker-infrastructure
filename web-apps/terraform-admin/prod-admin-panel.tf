module "prod-admin-panel" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite?ref=acm_removed"
  domain = "admin.treetracker.org"
  error_document = "index.html"
}
