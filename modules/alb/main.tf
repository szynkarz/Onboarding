data "aws_acm_certificate" "this" {
  domain      = var.alb_dns_name
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_security_group" "alb_sg" {
  name        = "${var.alb_base_tag}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
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
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.alb_base_tag}-alb-sg"
  }
}

resource "aws_lb" "alb" {
  name                             = "${var.alb_base_tag}-alb"
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [aws_security_group.alb_sg.id]
  subnets                          = [for subnet in aws_subnet.lb_subnet : subnet.id]
  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = false

  tags = {
    Name = "${var.alb_base_tag}-alb"
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
    Name = "${var.alb_base_tag}-tg"
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
  name    = var.alb_dns_name
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}

# resource "aws_security_group" "asg_sg" {
#   name   = "${var.alb_base_tag}-asg-sg"
#   vpc_id = var.vpc_id

#   ingress {
#     from_port       = var.port
#     to_port         = var.port
#     protocol        = "-1"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   ingress {
#     from_port       = 4180
#     to_port         = 4180
#     protocol        = "-1"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   ingress {
#     from_port       = 5601
#     to_port         = 5601
#     protocol        = "-1"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   ingress {
#     from_port       = 9200
#     to_port         = 9200
#     protocol        = "-1"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   ingress {
#     from_port       = 443
#     to_port         = 443
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.alb_base_tag}-asg-sg"
#   }
# }


resource "aws_launch_template" "lt" {
  name                   = "${var.alb_base_tag}-lt"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  update_default_version = true
  key_name               = var.key_name
  user_data              = var.user_data
  vpc_security_group_ids = [aws_security_group.alb_sg.id]
}


resource "aws_autoscaling_group" "asg" {
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  vpc_zone_identifier = [for subnet in aws_subnet.asg_subnet : subnet.id]
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  target_group_arns         = [aws_lb_target_group.asg.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 600
}


