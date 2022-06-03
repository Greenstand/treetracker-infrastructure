variable "do_token" {}
provider "digitalocean" {
  token = var.do_token
}
terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "1.22.2"
    }
  }
}
