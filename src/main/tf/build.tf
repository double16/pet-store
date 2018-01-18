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
          "${aws_s3_bucket.codebuild_bucket.arn}/*"
      ]
     },
     {
      "Action": [
          "ecr:GetAuthorizationToken"
      ],
      "Resource": "*",
      "Effect": "Allow"
     },
     {
      "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
      ],
      "Resource": "${aws_ecr_repository.app_repo.arn}",
      "Effect": "Allow"
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
    location = "${aws_s3_bucket.codebuild_bucket.bucket}"
    namespace_type = "BUILD_ID"
    path = "artifacts"
  }

//  cache {
//    type = "S3"
//    location = "${aws_s3_bucket.codebuild_bucket.bucket}"
//    path = "cache"
//  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "827184202067.dkr.ecr.us-east-1.amazonaws.com/gradle-webapp-build-base:2018.01.1"
    type = "LINUX_CONTAINER"
    privileged_mode = true

    environment_variable {
      "name" = "DOCKER_REGISTRY_URL"
      "value" = "${aws_ecr_repository.app_repo.repository_url}"
    }

    environment_variable {
      "name" = "STATIC_BUCKET"
      "value" = "${aws_s3_bucket.static_content.bucket}"
    }
  }

  source {
    type = "GITHUB"
    location = "https://github.com/double16/pet-store.git"
    auth {
      type = "OAUTH"
    }
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

resource "aws_s3_bucket" "static_content" {
  bucket = "pet-store-static_content-${terraform.workspace}"
  acl    = "private"

  tags {
    "Application" = "pet-store"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_ecr_repository" "app_repo" {
  name = "pet-store-app"
}

resource "aws_ecr_lifecycle_policy" "app_repo_policy" {
  repository = "${aws_ecr_repository.app_repo.name}"

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire images older than 14 days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
