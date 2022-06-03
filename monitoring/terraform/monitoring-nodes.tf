resource "digitalocean_droplet" "monitor" {
  image    = "ubuntu-18-04-x64"
  name     = "prom-graf"
  region   = "sfo2"
  size     = "s-2vcpu-2gb"
  ssh_keys = ["37:45:4a:cd:5e:72:46:48:8f:69:e9:98:4f:6e:27:e0"] # SSH keys that need to be installed on the server.
  tags     = ["monitoring"]
}

resource "digitalocean_domain" "monitor-host" {
  name       = "monitoring.treetracker.org"
  ip_address = digitalocean_droplet.monitor.ipv4_address
}

resource "digitalocean_record" "CNAME-www" {
  domain = digitalocean_domain.monitor-host.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
}
