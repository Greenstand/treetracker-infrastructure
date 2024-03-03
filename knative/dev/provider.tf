terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.28.1"
    }
    kubernetes = "2.16.1"
    helm       = "2.8.0"
  }
}
