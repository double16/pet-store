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

resource "aws_security_group" "web_external" {
  name        = "${var.application_name}-web-external"
  description = "Web server exposed to the Internet"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    from_port   = 80
    to_port     = 80
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
  name = "/ecs/${var.application_name}"
  retention_in_days = "30"

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
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
  load_balancer {
    target_group_arn = "${aws_lb_target_group.app.arn}"
    container_name = "app"
    container_port = 8080
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.application_name}-${terraform.workspace}-lb-http-group"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.main.id}"
}

resource "aws_lb" "app" {
  name = "${var.application_name}-${terraform.workspace}"
  load_balancer_type = "application"
  internal = false
  subnets = [ "${aws_subnet.private1.id}", "${aws_subnet.private2.id}" ]
  security_groups = [ "${aws_security_group.web_external.id}" ]

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }

  depends_on = [ "aws_iam_policy.app_run" ]
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = "${aws_lb.app.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.app.arn}"
    type             = "forward"
  }
}
