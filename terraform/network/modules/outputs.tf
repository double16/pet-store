output "vpc" {
  value = "${data.aws_vpc.main.id}"
}

output "subnets" {
  value = {
    "public1" = "${aws_subnet.public1.id}"
    "public2" = "${aws_subnet.public2.id}"
    "private1" = "${aws_subnet.private1.id}"
    "private2" = "${aws_subnet.private2.id}"
  }
}
