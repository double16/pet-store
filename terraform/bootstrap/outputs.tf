output "admin_user" {
  value = "${aws_iam_access_key.admin.id}"
  sensitive = true
}

output "admin_secret" {
  value = "${aws_iam_access_key.admin.secret}"
  sensitive = true
}
