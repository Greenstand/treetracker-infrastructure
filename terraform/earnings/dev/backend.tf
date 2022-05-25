terraform {
  backend "s3" {
    bucket = "treetracker-infrastructure"
    key    = "terraform-earnings-dev.tfstate"
    region = "us-east-1"
  }
}
