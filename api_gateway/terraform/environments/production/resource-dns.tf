resource "digitalocean_record" "image_api_resource" {
  domain = "treetracker.org"
  type   = "A"
  name   = "prod-k8s-resource"
  value  = "167.172.12.67"
  ttl    = 3600
}
