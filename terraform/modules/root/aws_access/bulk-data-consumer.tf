resource "aws_iam_user" "bulk_data_consumer" {
  name = "Bulk-Data-Consumer-${var.environment}"
}

resource "aws_iam_access_key" "bulk_data_consumer_access_key" {
  user = aws_iam_user.bulk_data_consumer.name
}

output "bulk_data_consumer_keyid" {
  value = aws_iam_access_key.bulk_data_consumer_access_key.id
}

output "bulk_data_consumer_secret" {
  value = aws_iam_access_key.bulk_data_consumer_access_key.secret
}

resource "aws_iam_user_policy" "bulk_data_consumer_policy" {
  name = "bulk_data_consumer_policy"
  user = aws_iam_user.bulk_data_consumer.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Sid": "Terraform0",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${var.treetracker_batch_uploads_s3_bucket}/*"
    },
    {
      "Sid": "Terraform1",
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
      ],
      "Resource": "arn:aws:sqs:${var.aws_region}:${var.aws_account_id}:${var.treetracker_queue_name}"
    }
  ]
}
EOF
}

