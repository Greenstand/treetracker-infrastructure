terraform {
  backend "s3" {
    bucket = "treetracker-infrastructure"
    key    = "terraform-earnings-prod.tfstate"
    region = "us-east-1"
  }
}
