module "bastion" {
  source   = "github.com/Greenstand/terraform-digitalocean-bastion"
  region   = var.do_region
  prefix   = var.environment_long
  ssh_keys = var.bastion_ssh_key_fingerprint
  tags     = ["bastion"]
}
