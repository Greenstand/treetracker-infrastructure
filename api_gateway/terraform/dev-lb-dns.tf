resource "digitalocean_domain" "ambassador-host" {
  name = "dev-k8s.treetracker.org"
  ip_address = "138.197.233.41"
}

resource "digitalocean_record" "CNAME-www" {
  domain = digitalocean_domain.ambassador-host.name
  type = "CNAME"
  name = "www"
  value = "@"
}
