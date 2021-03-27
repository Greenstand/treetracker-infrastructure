terraform {
  backend "s3" {
    bucket = "treetracker-infrastructure"
    key    = "terraform-web-apps-admin.tfstate"
    region = "us-east-1"
  }
}
