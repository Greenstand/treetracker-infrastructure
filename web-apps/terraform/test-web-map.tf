module "test-web-map" {
  source         = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain         = "test.webmap.treetracker.org"
  error_document = "index.html"
}
