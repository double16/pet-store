provider "aws" {
  region = "${var.region}"
  profile = "admin"
  version = "~> 1.22"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}
