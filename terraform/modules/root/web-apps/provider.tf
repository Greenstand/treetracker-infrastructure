terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  allowed_account_ids = [ var.aws_account_id ]
  region = var.aws_region
}

