resource "aws_iam_user" "bulk_data_consumer_prod" {
  name = "Bulk-Data-Consumer-Prod"
}

resource "aws_iam_access_key" "bulk_data_consumer_prod_access_key" {
  user = aws_iam_user.bulk_data_consumer_prod.name
}

output "bulk_data_consumer_prod_keyid" {
  value = aws_iam_access_key.bulk_data_consumer_prod_access_key.id
}

output "bulk_data_consumer_prod_secret" {
  value = aws_iam_access_key.bulk_data_consumer_prod_access_key.secret
}

resource "aws_iam_user_policy" "bulk_data_consumer_prod_policy" {
  name = "bulk_data_consumer_prod_policy"
  user = aws_iam_user.bulk_data_consumer_prod.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Sid": "Terraform0",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::treetracker-prod-batch-uploads/*"
    },
    {
      "Sid": "Terraform1",
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
      ],
      "Resource": "arn:aws:sqs:eu-central-1:053061259712:treetracker-prod-queue"
    }
  ]
}
EOF
}

