resource "aws_iam_user" "warren_person_user" {
  name = "warren"
}

resource "aws_iam_access_key" "warren_person_user_access_key" {
  user = aws_iam_user.warren_person_user.name
}

output "warren_keyid" {
  value = aws_iam_access_key.warren_person_user_access_key.id
}

output "warren_secret" {
  value = aws_iam_access_key.warren_person_user_access_key.secret
}

resource "aws_iam_user_policy" "warren_person_user_policy" {
  name = "warren_person_user_policy"
  user = aws_iam_user.warren_person_user.name

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action": "s3:GetObject",
         "Resource":"arn:aws:s3:::treetracker-production-images/*"
      },
      {
         "Effect": "Allow",
         "Action": "s3:ListBucket",
         "Resource": "arn:aws:s3:::herbarium.treetracker.org"
      }
   ]
}
EOF
}

