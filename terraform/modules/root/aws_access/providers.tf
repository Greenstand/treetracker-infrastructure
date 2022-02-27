terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  allowed_account_ids = [ var.aws_account_id ]
  region = var.aws_region
}
