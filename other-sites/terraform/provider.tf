variable "TREETRACKER_AWS_ACCESS_KEY_ID" {}
variable "TREETRACKER_AWS_SECRET_ACCESS_KEY" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  access_key = var.TREETRACKER_AWS_ACCESS_KEY_ID
  secret_key = var.TREETRACKER_AWS_SECRET_ACCESS_KEY
}

