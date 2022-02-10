resource "aws_s3_bucket" "payments_upload_bucket" {
  bucket = "payments-batch-upload"
}

resource "aws_iam_user" "payments_upload_bucket_user" {
  name = "Payments-Upload-User"
}

resource "aws_iam_access_key" "payments_upload_bucket_user_access_key" {
  user = aws_iam_user.payments_upload_bucket_user.name
}

output "payments_upload_bucket_user_keyid" {
  value = aws_iam_access_key.payments_upload_bucket_user_access_key.id
}

output "payments_upload_bucket_user_secret" {
  value = aws_iam_access_key.payments_upload_bucket_user_access_key.secret
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
