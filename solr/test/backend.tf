
terraform {
  # DigitalOcean uses the S3 spec.
  backend "s3" {
    bucket   = "treetracker-test-terraform"
    key      = "terraform-solr.tfstate"
    endpoint = "https://sfo2.digitaloceanspaces.com"
    # DO uses the S3 format
    # eu-west-1 is used to pass TF validation
    # Region is ACTUALLY sfo2 on DO
    region = "eu-west-1"
    # Deactivate a few checks as TF will attempt these against AWS
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
  }
}
