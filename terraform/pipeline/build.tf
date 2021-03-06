resource "aws_cloudwatch_log_group" "app" {
  name = "/aws/codebuild/${var.application_name}"
  retention_in_days = "30"

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_codecommit_repository" "application" {
  repository_name = "${var.application_name}"
  description = "${var.application_description}"
  default_branch = "master"
}

resource "aws_codebuild_project" "codebuild_project" {
  name = "${var.application_name}"
  description = "${var.application_description}"
  build_timeout = "40"
  service_role = "${aws_iam_role.codebuild_role.arn}"

  source {
    type = "CODEPIPELINE"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  cache {
    type = "S3"
    location = "${aws_s3_bucket.codebuild_bucket.bucket}/cache"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image = "827184202067.dkr.ecr.us-east-1.amazonaws.com/gradle-webapp-build-base:2018.04.2"
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

    environment_variable {
      "name" = "ARTIFACT_BUCKET"
      "value" = "${aws_s3_bucket.codebuild_bucket.bucket}"
    }
  }

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket" "codebuild_bucket" {
  bucket = "codebuild-${var.application_name}"
  acl    = "private"

  lifecycle_rule {
    id      = "cache"
    enabled = true
    prefix  = "cache/"
    expiration {
      days = 30
      expired_object_delete_marker = false
    }
  }

  lifecycle_rule {
    id      = "all"
    enabled = true
    expiration {
      days = 30
      expired_object_delete_marker = false
    }
  }

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket" "static_content" {
  bucket = "${var.application_name}-static-content-${terraform.workspace}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_ecr_repository" "app_repo" {
  name = "${var.application_name}-app"
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
