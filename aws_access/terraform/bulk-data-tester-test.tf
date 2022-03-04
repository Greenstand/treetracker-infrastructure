resource "aws_iam_user" "bulk_data_tester_test" {
  name = "Bulk-Data-Tester-Test"
}

resource "aws_iam_access_key" "bulk_data_tester_test_access_key" {
  user = aws_iam_user.bulk_data_tester_test.name
}

output "bulk_data_tester_test_keyid" {
  value = aws_iam_access_key.bulk_data_tester_test_access_key.id
}

output "bulk_data_tester_test_secret" {
  value = aws_iam_access_key.bulk_data_tester_test_access_key.secret
}

resource "aws_iam_user_policy" "bulk_data_tester_test_policy" {
  name = "bulk_data_tester_test_policy"
  user = aws_iam_user.bulk_data_tester_test.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
    {
      "Sid": "Terraform0",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::treetracker-test-batch-uploads/*"
    },
    {
      "Sid": "Terraform01",
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::treetracker-dev-batch-uploads/*"
    },
    {
      "Sid": "Terraform1",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ], 
      "Resource": "arn:aws:s3:::treetracker-production-batch-uploads/*"
    },
    {
      "Sid": "Terraform2",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ], 
      "Resource": "arn:aws:s3:::treetracker-production-batch-uploads"
    }
  ]
}
EOF
}

