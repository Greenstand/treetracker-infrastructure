module "staging-web-map" {
  source         = "github.com/Greenstand/terraform-aws-staticwebsite"
  domain         = "staging-map.treetracker.org"
  error_document = "index.html"
  routing_rules  = <<EOF
[{
  "Condition" : {
    "KeyPrefixEquals" : "finorx-"
  },
  "Redirect"  : {
    "HostName"             : "staging-map.treetracker.org",
      "ReplaceKeyPrefixWith" : "?tree_name="
  }
},
{
  "Condition" : {
    "KeyPrefixEquals" : "tree/"
  },
  "Redirect"  : {
    "HostName"             : "staging-map.treetracker.org",
      "ReplaceKeyPrefixWith" : "?tree_name="
  }
}]
EOF

}
