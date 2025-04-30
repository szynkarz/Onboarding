resource "aws_vpc" "lambda" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.base_tag}-vpc"
  }
}

resource "aws_eip" "nat_eip" {
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lambda.id

  tags = {
    Name = "${var.base_tag}-igw"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.lambda_subnet-public.id
  depends_on    = [aws_internet_gateway.igw]
  tags = {
    Name = "${var.base_tag}-nat-gw"
  }

}

resource "aws_route_table" "rt-nat" {
  vpc_id = aws_vpc.lambda.id

  route {
    cidr_block     = aws_vpc.lambda.cidr_block
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "${var.base_tag}-rt"
  }
}

resource "aws_route_table" "rt-igw" {
  vpc_id = aws_vpc.lambda.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.base_tag}-rt"
  }
}

resource "aws_route_table_association" "rta-nat" {
  subnet_id      = aws_subnet.lambda_subnet-private.id
  route_table_id = aws_route_table.rt-nat.id
}

resource "aws_route_table_association" "rta-igw" {
  subnet_id      = aws_subnet.lambda_subnet-public.id
  route_table_id = aws_route_table.rt-igw.id
}

resource "aws_subnet" "lambda_subnet-private" {
  vpc_id            = aws_vpc.lambda.id
  cidr_block        = cidrsubnet(aws_vpc.lambda.cidr_block, 8, 10)
  availability_zone = "${var.region}a"
  tags = {
    Name = "${var.base_tag}-subnet"
  }
}

resource "aws_subnet" "lambda_subnet-public" {
  vpc_id                  = aws_vpc.lambda.id
  cidr_block              = cidrsubnet(aws_vpc.lambda.cidr_block, 8, 20)
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.base_tag}-subnet"
  }
}


resource "aws_security_group" "lambda_sg" {
  vpc_id = aws_vpc.lambda.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.base_tag}-sg"
  }
}
