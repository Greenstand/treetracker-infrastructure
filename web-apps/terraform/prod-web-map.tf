module "prod-web-map" {
  source  = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain = "webmap.treetracker.org"
  error_document = "index.html"
  routing_rules = <<EOF
[{
  "Condition" : {
    "KeyPrefixEquals" : "finorx-"
  },
  "Redirect"  : {
    "HostName"             : "map.treetracker.org",
      "ReplaceKeyPrefixWith" : "?tree_name="
  }
},
{
  "Condition" : {
    "KeyPrefixEquals" : "tree/"
  },
  "Redirect"  : {
    "HostName"             : "map.treetracker.org",
      "ReplaceKeyPrefixWith" : "?tree_name="
  }
}]
EOF

}
