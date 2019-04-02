# Ensure domain exists in https://cloud.digitalocean.com/networking/domains/?i=d79377

resource "digitalocean_domain" "treetracker_org" {
  name = "treetracker.org"
}

resource "digitalocean_record" "treetracker" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "A"
  name   = "@"
  value  = "206.189.207.26"
}

resource "digitalocean_record" "ci" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "A"
  name   = "ci"
  value  = "138.68.194.18"
}

resource "digitalocean_record" "onetreeplanted" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "A"
  name   = "onetreeplanted"
  value  = "138.68.201.38"
}

resource "digitalocean_record" "test" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "A"
  name   = "test"
  value  = "174.138.107.11"
}

resource "digitalocean_record" "web" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "A"
  name   = "web"
  value  = "69.163.172.21"
}

resource "digitalocean_record" "greenstand" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "A"
  name   = "greenstand"
  value  = "192.30.252.153"
}

resource "digitalocean_record" "dev" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "A"
  name   = "dev"
  value  = "138.68.201.38"
}

resource "digitalocean_record" "www" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "CNAME"
  name   = "www"
  value  = "treetracker.org."
}

resource "digitalocean_record" "api" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "CNAME"
  name   = "api"
  value  = "treetracker.org."
}

resource "digitalocean_record" "mx_1" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "MX"
  name   = "@"
  value  = "aspmx.l.google.com."
  priority = "1"
}
resource "digitalocean_record" "mx_2" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "MX"
  name   = "@"
  value  = "alt1.aspmx.l.google.com."
  priority = "5"
}
resource "digitalocean_record" "mx_3" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "MX"
  name   = "@"
  value  = "alt2.aspmx.l.google.com."
  priority = "5"
}
resource "digitalocean_record" "mx_4" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "MX"
  name   = "@"
  value  = "alt3.aspmx.l.google.com."
  priority = "10"
}
resource "digitalocean_record" "mx_5" {
  domain = "${digitalocean_domain.treetracker_org.name}"
  type   = "MX"
  name   = "@"
  value  = "alt4.aspmx.l.google.com."
  priority = "10"
}