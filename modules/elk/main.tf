data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "elk_sg" {
  vpc_id = aws_vpc.vpc.id
  name   = "${var.base_tag}-sg"
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [var.vpc_id.cidr_block]
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

module "alb-kibana" {
  source       = "../alb"
  user_data    = base64encode(file("./kibana.sh"))
  alb_base_tag = var.base_tag
  vpc_id       = aws_vpc.vpc.id
  gateway_id   = aws_internet_gateway.igw.id
  alb_dns_name = "kibana.${var.domain_name}"
  port         = 80
}

resource "aws_instance" "es-master" {
  security_groups = [aws_security_group.elk_sg.id]
  key_name        = var.key_name
  subnet_id       = aws_subnet.kibana_subnet.id
  instance_type   = var.instance_type
  ami             = data.aws_ami.al2.id
  user_data = templatefile("./es-master.sh", {
    SEED_HOSTS = join(
      [
        aws_instance.es-master.private_ip,
        aws_instance.es-data.private_ip,
      ],
      ","
    )
  })
  tags = {
    Name = "${var.base_tag}-es-master"
  }
}

resource "aws_instance" "es-data" {
  security_groups = [aws_security_group.elk_sg.id]
  key_name        = var.key_name
  subnet_id       = aws_subnet.kibana_subnet.id
  instance_type   = var.instance_type
  ami             = data.aws_ami.al2.id
  user_data       = file("./es-data.sh")
  tags = {
    Name = "${var.base_tag}-es-data"
  }
}

resource "aws_instance" "logstash" {
  depends_on      = [aws_instance.es-data, aws_instance.es-master]
  security_groups = [aws_security_group.elk_sg.id]
  key_name        = "key"
  subnet_id       = var.private_subnet_ids[0]
  instance_type   = var.instance_type
  ami             = data.aws_ami.al2.id
  user_data       = file("./logstash.sh")
  tags = {
    Name = "${var.base_tag}-logstash"
  }
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_zone" "elk" {
  name = var.local_domain_name
  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "es-master" {
  zone_id = aws_route53_zone.elk.zone_id
  name    = "es-master.${var.local_domain_name}"
  ttl     = 300
  type    = "A"
  records = [aws_instance.es-master[*].private_ip]
}

resource "aws_route53_record" "es-data" {
  zone_id = aws_route53_zone.elk.zone_id
  name    = "es-data.${var.local_domain_name}"
  ttl     = 300
  type    = "A"
  records = [aws_instance.es-data[*].private_ip]
}

resource "aws_route53_record" "logstash" {
  zone_id = aws_route53_zone.elk.zone_id
  name    = "logstash.${var.local_domain_name}"
  ttl     = 300
  type    = "A"
  records = [aws_instance.logstash[*].private_ip]
}




