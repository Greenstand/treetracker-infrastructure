resource "digitalocean_domain" "ambassador-host" {
  name = "dev-k8s.treetracker.org"
  ip_address = "134.209.142.182"
}

resource "digitalocean_record" "CNAME-www" {
  domain = digitalocean_domain.ambassador-host.name
  type = "CNAME"
  name = "www"
  value = "@"
}
