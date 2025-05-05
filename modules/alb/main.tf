data "aws_acm_certificate" "this" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

data "aws_route53_zone" "this" {
  name         = regex("\\w+\\.\\w+$", var.domain_name)
  private_zone = false
}

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.base_tag}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.base_tag}-alb-sg"
  }
}

resource "aws_lb" "alb" {
  name                             = "${var.base_tag}-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb_sg.id]
  subnets                          = [for subnet in var.public_subnet_ids : subnet]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  tags = {
    Name = "${var.base_tag}-alb"
  }
}

resource "aws_lb_target_group" "asg" {
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name = "${var.base_tag}-tg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn    = aws_lb_target_group.asg.arn
}

resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_launch_template" "lt" {
  name                   = "${var.base_tag}-lt"
  image_id               = data.aws_ami.al2.id
  instance_type          = var.instance_type
  update_default_version = true
  key_name               = var.key_name
  user_data              = var.user_data
  vpc_security_group_ids = [aws_security_group.alb_sg.id]
}


resource "aws_autoscaling_group" "asg" {
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  vpc_zone_identifier = [for subnet in var.private_subnet_ids : subnet]
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  target_group_arns         = [aws_lb_target_group.asg.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 600
}


