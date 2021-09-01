resource "aws_iam_user" "bulk_data_consumer_test" {
  name = "Bulk-Data-Consumer-Test"
}

resource "aws_iam_access_key" "bulk_data_consumer_test_access_key" {
  user = aws_iam_user.bulk_data_consumer_test.name
}

output "bulk_data_consumer_test_keyid" {
  value = aws_iam_access_key.bulk_data_consumer_test_access_key.id
}

output "bulk_data_consumer_test_secret" {
  value = aws_iam_access_key.bulk_data_consumer_test_access_key.secret
}

resource "aws_iam_user_policy" "bulk_data_consumer_test_policy" {
  name = "bulk_data_consumer_test_policy"
  user = aws_iam_user.bulk_data_consumer_test.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Sid": "Terraform0",
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::treetracker-test-batch-uploads/*"
    },
    {
      "Sid": "Terraform1",
      "Effect": "Allow",
      "Action": [
        "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
      ],
      "Resource": "arn:aws:sqs:eu-central-1:053061259712:treetracker-test-queue"
    }
  ]
}
EOF
}

