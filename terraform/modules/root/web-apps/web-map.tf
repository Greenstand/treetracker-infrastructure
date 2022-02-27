module "web-map" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain = "webmap.treetracker.org"
  error_document = "index.html"
  routing_rules = var.web-map_routing-rules
}
