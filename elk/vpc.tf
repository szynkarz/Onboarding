resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.base_tag}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.base_tag}-igw"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.base_tag}-rt"
  }
}

resource "aws_route_table_association" "kibana_subnet_association" {
  subnet_id      = aws_subnet.kibana_subnet.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "elasticsearch_subnet_association" {
  for_each       = aws_subnet.elasticsearch_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_subnet" "kibana_subnet" {
  # for_each                = { for idx, az in var.az_list : idx => az }
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, 10)
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.base_tag}-kibana_subnet-1"
  }
}

resource "aws_subnet" "elasticsearch_subnet" {

  for_each                = { for idx, az in var.az_list : idx => az }
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(var.cidr_block, 8, tonumber(each.key) + 41)
  availability_zone       = "${var.region}${each.value}"

  tags = {
    Name = "${var.base_tag}-elasticsearch_subnet-${each.key + 1}"
  }
}


