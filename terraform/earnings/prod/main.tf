variable "aws_region" {
  type = string
}

variable "aws_bucket_name" {
  type = string
}

variable "payments_upload_user" {
  type = string
}

output "print-bucket" {
  value = var.aws_bucket_name
}

output "print-region" {
  value = var.aws_region
}

resource "aws_s3_bucket" "payments_upload_bucket" {
  bucket = var.aws_bucket_name
  region = var.aws_region
}

resource "aws_iam_user" "payments_upload_bucket_user" {
  name = var.payments_upload_user
}

resource "aws_iam_access_key" "payments_upload_bucket_user_access_key" {
  user = aws_iam_user.payments_upload_bucket_user.name
}

output "payments_upload_bucket_user_keyid" {
  value = aws_iam_access_key.payments_upload_bucket_user_access_key.id
}

output "payments_upload_bucket_user_secret" {
  value     = aws_iam_access_key.payments_upload_bucket_user_access_key.secret
  sensitive = true
}

resource "aws_iam_user_policy" "payments_upload_bucket_user_policy" {
  name = "payments_upload_bucket_user_policy"
  user = aws_iam_user.payments_upload_bucket_user.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Sid": "Terraform0",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
       ], 
      "Resource": "arn:aws:s3:::payments-batch-upload/*"
    }
  ]
}
EOF
}
