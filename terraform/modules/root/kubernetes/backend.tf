
terraform {
  # DigitalOcean uses the S3 spec.
  backend "s3" {

    #key    = "terraform-kubernetes.tfstate"
    #endpoint = "https://sfo2.digitaloceanspaces.com"

    region = "eu-west-1"

    # Deactivate a few checks as TF will attempt these against AWS
    skip_credentials_validation = true
    # skip_get_ec2_platforms = true
    # skip_requesting_account_id = true
    skip_metadata_api_check = true
  }
}
