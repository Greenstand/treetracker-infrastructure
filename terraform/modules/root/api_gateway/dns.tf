
resource "digitalocean_domain" "ambassador-host" {
  name = var.ambassador_host_domain_name
  ip_address = var.ambassador_host_load_balancer_ip_address
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


#resource "digitalocean_domain" "ambassador-host-test" {
#  name = "test-k8s.treetracker.org"
#  ip_address = "157.230.74.182"
#}

#resource "digitalocean_domain" "ambassador-host-prod" {
#  name = "prod-k8s.treetracker.org"
#  ip_address = "167.172.12.67"
#}

