resource "aws_s3_bucket" "production_backups" {
  bucket = "treetracker-production-backups"
  acl    = "private"

  tags = {
    Name        = "Production Backups"
    Environment = "Production"
  }
}
