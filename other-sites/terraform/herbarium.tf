module "staticwebsite" {
  source         = "github.com/Greenstand/terraform-aws-staticwebsite?ref=with_cert"
  domain         = "herbarium.greenstand.org"
  error_document = "index.html"
}
