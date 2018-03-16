resource "aws_vpc" "main" {
  cidr_block = "10.192.0.0/16"

  tags {
    "Name" = "${var.application_name}"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    "Name" = "${var.application_name}"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_eip" "nat1_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat1" {
  allocation_id = "${aws_eip.nat1_eip.id}"
  subnet_id = "${aws_subnet.public1.id}"
  depends_on = [
    "aws_internet_gateway.gw"]

  tags {
    "Name" = "${var.application_name} nat AZ1"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_eip" "nat2_eip" {
  vpc = true
}

resource "aws_nat_gateway" "nat2" {
  allocation_id = "${aws_eip.nat2_eip.id}"
  subnet_id = "${aws_subnet.public2.id}"
  depends_on = [
    "aws_internet_gateway.gw"]

  tags {
    "Name" = "${var.application_name} nat AZ2"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_subnet" "public1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.192.10.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    "Name" = "${var.application_name} public subnet AZ1"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_subnet" "public2" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.192.11.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags {
    "Name" = "${var.application_name} public subnet AZ2"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_subnet" "private1" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.192.20.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

  tags {
    "Name" = "${var.application_name} private subnet AZ1"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_subnet" "private2" {
  vpc_id = "${aws_vpc.main.id}"
  cidr_block = "10.192.21.0/24"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

  tags {
    "Name" = "${var.application_name} private subnet AZ2"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    "Name" = "${var.application_name} public route table"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_route" "default_public_route" {
  route_table_id = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.gw.id}"
}

resource "aws_route_table_association" "public1" {
  subnet_id      = "${aws_subnet.public1.id}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "public2" {
  subnet_id      = "${aws_subnet.public2.id}"
  route_table_id = "${aws_route_table.public.id}"
}


resource "aws_route_table" "private1" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    "Name" = "${var.application_name} private1 route table"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_route" "default_private1_route" {
  route_table_id = "${aws_route_table.private1.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat1.id}"
}

resource "aws_route_table_association" "private1" {
  subnet_id      = "${aws_subnet.private1.id}"
  route_table_id = "${aws_route_table.private1.id}"
}


resource "aws_route_table" "private2" {
  vpc_id = "${aws_vpc.main.id}"

  tags {
    "Name" = "${var.application_name} private2 route table"
    "Application" = "${var.application_name}"
    "Environment" = "${terraform.workspace}"
  }
}

resource "aws_route" "default_private2_route" {
  route_table_id = "${aws_route_table.private2.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.nat2.id}"
}

resource "aws_route_table_association" "private2" {
  subnet_id      = "${aws_subnet.private2.id}"
  route_table_id = "${aws_route_table.private2.id}"
}
