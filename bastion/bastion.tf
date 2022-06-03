module "bastion" {
  source   = "github.com/Greenstand/terraform-digitalocean-bastion"
  region   = "nyc1"
  prefix   = "production"
  ssh_keys = ["8c:9b:4c:e4:a5:b1:08:c7:3b:bc:b6:9a:21:86:3f:3d"]
  tags     = ["bastion"]
}
