#variable "host_name" {}
#variable "load_balancer_ip_address" {}


#resource "digitalocean_domain" "ambassador-host" {
#  name = var.host_name
#  ip_address = var.load_balancer_ip_address
#}

resource "digitalocean_domain" "ambassador-host" {
  name       = "dev-k8s.treetracker.org"
  ip_address = "134.209.142.182"
}

resource "digitalocean_record" "CNAME-www" {
  domain = digitalocean_domain.ambassador-host.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
}


# NOTE
# since the dev account controls the dns recores
# all dns is managed here

resource "digitalocean_domain" "ambassador-host-test" {
  name       = "test-k8s.treetracker.org"
  ip_address = "157.230.74.182"
}

resource "digitalocean_domain" "ambassador-host-prod" {
  name       = "prod-k8s.treetracker.org"
  ip_address = "167.172.12.67"
}


