resource "aws_iam_user" "cam_person_user" {
  name = "cam"
}

resource "aws_iam_access_key" "cam_person_user_access_key" {
  user = aws_iam_user.cam_person_user.name
}

output "cam_keyid" {
  value = aws_iam_access_key.cam_person_user_access_key.id
}

output "cam_secret" {
  value = aws_iam_access_key.cam_person_user_access_key.secret
}

resource "aws_iam_user_policy" "cam_person_user_policy" {
  name = "cam_person_user_policy"
  user = aws_iam_user.cam_person_user.name

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement":[
      {
         "Effect":"Allow",
         "Action": "s3:*Object",
         "Resource":"arn:aws:s3:::herbarium.treetracker.org/*"
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

