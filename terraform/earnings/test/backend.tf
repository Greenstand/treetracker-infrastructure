terraform {
  backend "s3" {
    bucket = "treetracker-infrastructure"
    key    = "terraform-earnings-test.tfstate"
    region = "us-east-1"
  }
}
