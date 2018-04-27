output "app_repository_url" {
  value = "${aws_ecr_repository.app_repo.repository_url}"
}

output "static_url" {
  value = "http://${aws_s3_bucket.static_content.website_endpoint}/"
}
