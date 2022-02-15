
output "payments_upload_bucket_user_keyid" {
  value = aws_iam_access_key.payments_upload_bucket_user_access_key.id
}

output "payments_upload_bucket_user_secret" {
  value = aws_iam_access_key.payments_upload_bucket_user_access_key.secret
}
