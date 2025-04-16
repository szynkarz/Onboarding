resource "aws_security_group" "kibana_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "${var.base_tag}-kibana-sg"
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
    Name = "${var.base_tag}-kibana-sg"
  }
}

resource "aws_instance" "name" {
  security_groups = [aws_security_group.kibana_sg.id]

  subnet_id     = aws_subnet.kibana_subnet.id
  instance_type = var.instance_type
  ami           = var.ami_id
  user_data     = file("./elk.sh")

  tags = {
    Name = "${var.base_tag}-kibana"
  }

}

# data "aws_route53_zone" "this" {
#   name         = var.domain_name
#   private_zone = false
# }

# resource "aws_eip" "kibana_eip" {
#   instance = aws_instance.name.id

# }

# resource "aws_route53_record" "kibana" {
#   zone_id = data.aws_route53_zone.this.zone_id
#   name    = "elk.${data.aws_route53_zone.this.name}"
#   type    = "A"
#   records = [aws_eip.kibana_eip.public_ip]
# }


