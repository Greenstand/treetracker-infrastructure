resource "aws_s3_bucket" "backups" {
  bucket = var.treetracker_backup_bucket # "treetracker-production-backups"
  acl    = "private"

  tags = {
    Name        = "Production Backups"
    Environment = "Production"
  }
}
