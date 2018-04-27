
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

resource "aws_cloudwatch_event_target" "pipeline" {
  rule      = "${aws_cloudwatch_event_rule.oncommit.name}"
  arn       = "${aws_codepipeline.application.arn}"
  role_arn  = "${aws_iam_role.oncommit_role.arn}"
}
