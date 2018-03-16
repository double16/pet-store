resource "aws_security_group" "web_internal" {
  name        = "${var.application_name}-web-internal"
  description = "Web server using an internal port"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name = "/aws/codebuild/${var.application_name}"
  retention_in_days = "30"

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_iam_policy" "app_run" {
  name = "${var.application_name}-ecs-run"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        "Resource": "*"
      },
      {
          "Effect": "Allow",
          "Resource": [
              "${aws_cloudwatch_log_group.app.arn}",
              "${aws_cloudwatch_log_group.app.arn}:*"
          ],
          "Action": [
              "logs:CreateLogGroup",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
          ]
      }
    ]
}
POLICY
}

resource "aws_iam_role" "app_run" {
  name = "${var.application_name}-ecs-run"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy_attachment" "app_run_policy_attachment" {
  name = "codebuild-policy-attachment-${var.application_name}"
  policy_arn = "${aws_iam_policy.app_run.arn}"
  roles = [
    "${aws_iam_role.app_run.id}"
  ]
}

resource "aws_ecs_task_definition" "app" {
  family = "${var.application_name}"
  execution_role_arn = "${aws_iam_role.app_run.arn}"
  container_definitions = "${file("task-defs/pet-store.json")}"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "512"
  memory = "1024"
}

resource "aws_ecs_service" "app" {
  name = "${var.application_name}"
  cluster = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.app.arn}"
  launch_type = "FARGATE"
  desired_count = 2
  network_configuration {
    subnets = [ "${aws_subnet.private1.id}", "${aws_subnet.private2.id}" ]
    security_groups = [ "${aws_security_group.web_internal.id}" ]
  }
}
