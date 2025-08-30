data "aws_region" "current" {}
data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.admin_name}-vpc"
  }
}

resource "aws_subnet" "main-southeast-1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-southeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.admin_name}-subnet-1a"
  }
}

resource "aws_subnet" "main-southeast-1b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.admin_name}-subnet-1b"
  }
}

resource "aws_subnet" "main-southeast-1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-southeast-1c"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.admin_name}-subnet-1c"
  }
}
