
resource "aws_s3_bucket" "payments_upload_bucket" {
  bucket = "payments-batch-upload"
}
