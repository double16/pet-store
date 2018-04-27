terraform {
  backend "s3" {
    # interpolation is not allowed
    profile = "pet-store_deployer"
    bucket = "pet-store-state"
    # we're using the same bitbucket for all state, so we need a unique key per directory
    key = "bootstrap"
    # forcing the region for the state bucket because we only want one
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "terraform-state-lock"
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "pet-store-state"
  acl = "private"
  region = "us-east-1"
  versioning {
    enabled = true
  }
  lifecycle_rule {
    enabled = true

    noncurrent_version_transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      days = 60
    }
  }

  tags {
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_dynamodb_table" "state-lock-table" {
  name  = "terraform-state-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }

  tags {
    "Application" = "Terraform"
    "Environment" = "${terraform.workspace}"
  }
}
