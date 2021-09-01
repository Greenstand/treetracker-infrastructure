resource "aws_iam_user" "bulk_data_consumer_dev" {
  name = "Bulk-Data-Consumer-Dev"
}

resource "aws_iam_access_key" "bulk_data_consumer_dev_access_key" {
  user = aws_iam_user.bulk_data_consumer_dev.name
}

output "bulk_data_consumer_dev_keyid" {
  value = aws_iam_access_key.bulk_data_consumer_dev_access_key.id
}

output "bulk_data_consumer_dev_secret" {
  value = aws_iam_access_key.bulk_data_consumer_dev_access_key.secret
}

resource "aws_iam_user_policy" "bulk_data_consumer_dev_policy" {
  name = "bulk_data_consumer_dev_policy"
  user = aws_iam_user.bulk_data_consumer_dev.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Sid": "Terraform0",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::treetracker-dev-batch-uploads/*"
    },
    {
      "Sid": "Terraform1",
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
      ],
      "Resource": "arn:aws:sqs:eu-central-1:053061259712:treetracker-dev-queue"
    }
  ]
}
EOF
}

