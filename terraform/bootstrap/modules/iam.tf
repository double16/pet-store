
resource "aws_iam_group" "admins" {
  name = "${var.application_name}-admin-${terraform.workspace}"
  path = "/admins/"
}

resource "aws_iam_group_policy_attachment" "admins-admin" {
  group      = "${aws_iam_group.admins.name}"
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user" "admin" {
  name = "${var.application_name}-admin-${terraform.workspace}"
  path = "/admins/"
}

resource "aws_iam_access_key" "admin" {
  user = "${aws_iam_user.admin.name}"
}

resource "aws_iam_group_membership" "admins" {
  name = "${var.application_name}-admin-${terraform.workspace}-group-membership"

  users = [
    "${aws_iam_user.admin.name}",
  ]

  group = "${aws_iam_group.admins.name}"
}

resource "aws_iam_policy" "state" {
  name        = "${var.application_name}-state"
  path        = "/admins/"
  description = "Policy for maintaining infrastructure state"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::pet-store-state"
    },
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::pet-store-state/"
    },
    {
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": "${aws_dynamodb_table.state-lock-table.arn}"
    }
  ]
}
POLICY
}

resource "aws_iam_group_policy_attachment" "admins-state" {
  group      = "${aws_iam_group.admins.name}"
  policy_arn = "${aws_iam_policy.state.arn}"
}
