terraform {
  backend "s3" {
    # interpolation is not allowed
    profile = "pet-store_deployer"
    bucket = "pet-store-state"
    # we're using the same bitbucket for all state, so we need a unique key per directory
    key = "network"
    # forcing the region for the state bucket because we only want one
    region = "us-east-1"
    encrypt = true
    dynamodb_table = "pet-store-state-lock"
  }
}
