provider "aws" {
  region = "${var.region}"
  profile = "${var.application_name}_deployer"
  version = "~> 1.25"
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "terraform_remote_state" "network" {
  backend = "s3"
  workspace = "${terraform.workspace}"
  config {
    profile = "pet-store_deployer"
    bucket = "pet-store-state"
    key = "network"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}

data "terraform_remote_state" "pipeline" {
  backend = "s3"
  workspace = "${terraform.workspace}"
  config {
    profile = "pet-store_deployer"
    bucket = "pet-store-state"
    key = "pipeline"
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}
