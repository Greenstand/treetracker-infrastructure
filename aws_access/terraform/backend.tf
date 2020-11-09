provider "aws" {
  version                 = "~> 2.0"
  region                  = "us-east-1"
  shared_credentials_file = "~/.aws/credentials"
}
terraform {
  backend "s3" {
    bucket = "treetracker-infrastructure"
    key    = "cdn-info"
    region = "us-east-1"
  }
}
