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

resource "digitalocean_domain" "ambassador-host-test" {
  name = "test-k8s.treetracker.org"
  ip_address = "157.230.74.182"
}

