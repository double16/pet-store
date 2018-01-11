resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role-pet-store"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_policy" {
  name = "codebuild-policy-pet-store"
  path = "/service-role/"
  description = "Policy used in trust relationship with CodeBuild"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
          "s3:PutObject",
          "s3:GetObject"
      ],
      "Resource": [
          "arn:aws:s3:::codebuild-pet-store/*"
      ]
     }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name = "codebuild-policy-attachment-pet-store"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles = [
    "${aws_iam_role.codebuild_role.id}"]
}

resource "aws_codebuild_project" "codebuild_project" {
  name = "pet-store"
  description = "Pet Store example Grails project"
  build_timeout = "20"
  service_role = "${aws_iam_role.codebuild_role.arn}"

  artifacts {
    type = "S3"
    location = "codebuild-pet-store"
    namespace_type = "BUILD_ID"
    path = "artifacts"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "aws/codebuild/java:openjdk-8"
    type = "LINUX_CONTAINER"

    environment_variable {
      "name" = "SOME_KEY1"
      "value" = "SOME_VALUE1"
    }

    environment_variable {
      "name" = "SOME_KEY2"
      "value" = "SOME_VALUE2"
    }
  }

  source {
    type = "GITHUB"
    location = "https://github.com/double16/pet-store.git"
  }

  tags {
    "Application" = "pet-store"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket" "codebuild_bucket" {
  bucket = "codebuild-pet-store"
  acl    = "private"

  tags {
    "Application" = "pet-store"
    "Environment" = "${terraform.workspace}"
  }
}
