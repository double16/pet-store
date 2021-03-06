provider "aws" {
  region = "${var.region}"
  profile = "${var.application_name}_deployer"
  version = "~> 1.25"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}
