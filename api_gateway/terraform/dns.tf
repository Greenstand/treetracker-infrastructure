variable "host_name" {}
variable "load_balancer_ip_address" {}


resource "digitalocean_domain" "ambassador-host" {
  name = vars.name
  ip_address = vars.load_balancer_ip_address
}

resource "digitalocean_record" "CNAME-www" {
  domain = digitalocean_domain.ambassador-host.name
  type = "CNAME"
  name = "www"
  value = "@"
}

# this was included before environments were separated
#resource "digitalocean_domain" "ambassador-host-test" {
#  name = "test-k8s.treetracker.org"
#  ip_address = "157.230.74.182"
#}

