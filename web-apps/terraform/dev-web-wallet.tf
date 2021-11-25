module "dev-web-wallet" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain = "dev.wallet.treetracker.org"
  error_document = "index.html"
}
