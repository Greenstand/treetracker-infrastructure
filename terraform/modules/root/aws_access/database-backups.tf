resource "aws_iam_user" "database_packups_prod" {
  name = "Database-Backups-Prod"
}

resource "aws_iam_access_key" "database_packups_prod_access_key" {
  user = aws_iam_user.database_packups_prod.name
}

output "database_packups_prod_keyid" {
  value = aws_iam_access_key.database_packups_prod_access_key.id
}

output "database_packups_prod_secret" {
  value = aws_iam_access_key.database_packups_prod_access_key.secret
}

resource "aws_iam_user_policy" "database_packups_prod_policy" {
  name = "database_packups_prod_policy"
  user = aws_iam_user.database_packups_prod.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:ListBucket",
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject",
                "s3:PutObjectAcl"
            ],
            "Resource": [
                "arn:aws:s3:::treetracker-production-backups/*",
                "arn:aws:s3:::treetracker-production-backups"
            ]
        },
        {
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "arn:aws:s3:::*"
        }
    ]
}
EOF
}

