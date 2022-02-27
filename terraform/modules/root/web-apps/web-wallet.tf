module "web-wallet" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain = "${var.environment}.wallet.treetracker.org"
  error_document = "index.html"
}
