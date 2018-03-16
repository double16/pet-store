resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role-${var.application_name}"

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
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "codebuild_policy" {
  name = "codebuild-policy-${var.application_name}"
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
      "Effect": "Allow",
      "Action": [
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:UploadArchive",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:CancelUploadArchive"
      ],
      "Resource": "${aws_codecommit_repository.application.arn}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
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
     },
     {
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService",
        "iam:PassRole"
      ],
      "Resource": "*",
      "Effect": "Allow"
     }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "codebuild_policy_attachment" {
  name = "codebuild-policy-attachment-${var.application_name}"
  policy_arn = "${aws_iam_policy.codebuild_policy.arn}"
  roles = [
    "${aws_iam_role.codebuild_role.id}"
  ]
}

resource "aws_iam_role_policy_attachment" "codebuild_policy_attachment_ecs_poweruser" {
  role = "${aws_iam_role.codebuild_role.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

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
    image = "827184202067.dkr.ecr.us-east-1.amazonaws.com/gradle-webapp-build-base:2018.02.3"
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
    type = "CODECOMMIT"
    location = "${aws_codecommit_repository.application.clone_url_http}"
  }

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket" "codebuild_bucket" {
  bucket = "codebuild-${var.application_name}"
  acl    = "private"

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_s3_bucket" "static_content" {
  bucket = "${var.application_name}-static-content-${terraform.workspace}"
  acl    = "private"

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

resource "aws_codepipeline" "application" {
  name     = "${var.application_name}-${terraform.workspace}"
  role_arn = "${aws_iam_role.codebuild_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.codebuild_bucket.bucket}"
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source"]

      configuration {
        RepositoryName       = "${aws_codecommit_repository.application.repository_name}"
        BranchName           = "codebuild"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source"]
      output_artifacts = ["build"]
      version          = "1"

      configuration {
        ProjectName = "${aws_codebuild_project.codebuild_project.name}"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name             = "ECS"
      category         = "Deploy"
      owner            = "AWS"
      provider         = "ECS"
      input_artifacts  = ["build"]
      version          = "1"

      configuration {
        ClusterName = "${var.application_name}-${terraform.workspace}"
        ServiceName = "${var.application_name}"
        FileName = "imagedefinitions.json"
      }
    }
  }
}

resource "aws_cloudwatch_event_rule" "oncommit" {
  name = "codepipeline-${var.application_name}-master"
  description = "Amazon CloudWatch Events rule to automatically start your pipeline when a change occurs in the AWS CodeCommit source repository and branch."
  role_arn = ""

  event_pattern = <<PATTERN
{
  "source": [
    "aws.codecommit"
  ],
  "detail-type": [
    "CodeCommit Repository State Change"
  ],
  "resources": [
    "${aws_codecommit_repository.application.arn}"
  ],
  "detail": {
    "event": [
      "referenceCreated",
      "referenceUpdated"
    ]
  }
}
PATTERN
}

resource "aws_iam_role" "oncommit_role" {
  name = "${var.application_name}-${terraform.workspace}-oncommit"
  path = "/service-role/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "oncommit_policy" {
  name = "start-pipeline-execution-${var.application_name}-${terraform.workspace}"
  path = "/service-role/"
  description = "Policy used in trust relationship with CloudWatch"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "codepipeline:StartPipelineExecution"
            ],
            "Resource": [
                "${aws_codepipeline.application.arn}"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_policy_attachment" "oncommit_policy_attachment" {
  name = "${var.application_name}-${terraform.workspace}-oncommit-policy-attachment"
  policy_arn = "${aws_iam_policy.oncommit_policy.arn}"
  roles = [
    "${aws_iam_role.oncommit_role.id}"
  ]
}

resource "aws_cloudwatch_event_target" "pipeline" {
  rule      = "${aws_cloudwatch_event_rule.oncommit.name}"
  arn       = "${aws_codepipeline.application.arn}"
  role_arn  = "${aws_iam_role.oncommit_role.arn}"
}
