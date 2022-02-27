module "staging-admin-panel" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain = "staging-admin.treetracker.org"
  error_document = "index.html"
}
