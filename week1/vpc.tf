resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.base_tag}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${local.base_tag}-igw"
  }
}

resource "aws_subnet" "lb_subnet" {
  for_each                = { for idx, az in var.az_list : idx => az }
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, tonumber(each.key) + 11)
  availability_zone       = "${var.region}${each.value}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.base_tag}-lb_subnet-${each.key + 1}"
  }
}

resource "aws_subnet" "asg_subnet" {
  for_each          = { for idx, az in var.az_list : idx => az }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, tonumber(each.key) + 21)
  availability_zone = "${var.region}${each.value}"

  tags = {
    Name = "${local.base_tag}-asg_subnet-${each.key + 1}"
  }
}

resource "aws_subnet" "rds_subnet" {
  for_each          = { for idx, az in var.az_list : idx => az }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, tonumber(each.key) + 31)
  availability_zone = "${var.region}${each.value}"

  tags = {
    Name = "${local.base_tag}-rds_subnet-${each.key + 1}"
  }
}

