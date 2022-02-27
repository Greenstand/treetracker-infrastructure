terraform {
  # DigitalOcean uses the S3 spec.
  backend "s3" {

    #bucket = "greenstandtf"
    #key    = "terraform-api-gateway.tfstate"
    #endpoint = "https://sfo2.digitaloceanspaces.com"

    # DO uses the S3 backend. However, the S3 backend is hard-coded with AWS regions,
    # so we have to hard-code an AWS region here to pass validation.
    # the real 'endpoint' to a DigitalOcean region must be passed as an argument.
    region = "eu-west-1"

    # Deactivate a few checks as TF will attempt these against AWS

    skip_credentials_validation = true

    # skip_get_ec2_platforms = true
    # skip_requesting_account_id = true

    skip_metadata_api_check = true
  }
}
