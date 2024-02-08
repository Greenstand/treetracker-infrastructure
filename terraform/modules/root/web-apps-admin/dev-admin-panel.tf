module "dev-admin-panel" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain = "dev-admin.treetracker.org"
  error_document = "index.html"
}
