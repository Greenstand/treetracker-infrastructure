terraform {
  backend "s3" {
    bucket = "treetracker-infrastructure"
    key    = "terraform-web-apps.tfstate"
    region = "us-east-1"
  }
}
