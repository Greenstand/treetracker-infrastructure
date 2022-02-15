resource "aws_iam_user" "cf_user" {
  name = "cf_user"

  tags = {
    type = "api-user"
  }
}

resource "aws_iam_access_key" "cf_user_access_key" {
  user = aws_iam_user.cf_user.name
}

output "keyid" {
  value = aws_iam_access_key.cf_user_access_key.id
}

output "secret" {
  value = aws_iam_access_key.cf_user_access_key.secret
}

resource "aws_iam_user_policy" "cloudfront_user_policy" {
  name = "cf_user_policy"
  user = aws_iam_user.cf_user.name

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action":[
            "acm:ListCertificates",
            "cloudfront:*",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:PutMetricAlarm",
            "cloudwatch:GetMetricStatistics",
            "elasticloadbalancing:DescribeLoadBalancers",
            "iam:ListServerCertificates",
            "sns:ListSubscriptionsByTopic",
            "sns:ListTopics",
            "waf:GetWebACL",
            "waf:ListWebACLs"
         ],
         "Resource":"*"
      },
      {
         "Effect":"Allow",
         "Action":[
            "s3:ListAllMyBuckets",
            "s3:PutBucketPolicy"
         ],
         "Resource":"arn:aws:s3:::*"
      },
      {
         "Effect":"Allow",
         "Action": "s3:*Object",
         "Resource": [
             "arn:aws:s3:::dev-admin.treetracker.org/*",
             "arn:aws:s3:::dev.webmap.treetracker.org/*",
             "arn:aws:s3:::dev.wallet.treetracker.org/*",
             "arn:aws:s3:::test.webmap.treetracker.org/*",
             "arn:aws:s3:::webmap.treetracker.org/*",
             "arn:aws:s3:::test.admin.treetracker.org/*",
             "arn:aws:s3:::staging-admin.treetracker.org/*",
             "arn:aws:s3:::admin.treetracker.org/*"
         ]
      },
      {
         "Effect": "Allow",
         "Action": "s3:ListBucket",
         "Resource": [
             "arn:aws:s3:::dev-admin.treetracker.org",
             "arn:aws:s3:::dev.webmap.treetracker.org",
             "arn:aws:s3:::dev.wallet.treetracker.org",
             "arn:aws:s3:::test.webmap.treetracker.org",
             "arn:aws:s3:::webmap.treetracker.org",
             "arn:aws:s3:::test.admin.treetracker.org",
             "arn:aws:s3:::staging-admin.treetracker.org",
             "arn:aws:s3:::admin.treetracker.org"
         ]
      },
   ]
}
EOF
}

