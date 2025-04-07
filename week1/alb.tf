data "aws_acm_certificate" "this" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "my-alb"
  vpc_id  = aws_vpc.vpc.id
  subnets = [for subnet in aws_subnet.lb_subnet : subnet.id]

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
    ex-https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = data.aws_acm_certificate.this.arn
      ssl_policy      = "ELBSecurityPolicy-2016-08"

      forward = {
        target_group_key = "instance"
      }
    }
  }

  target_groups = {
    instance = {
      name_prefix = "h1"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      target_id   = "i-0f6d38a07d50d080f"
    }
  }

  route53_records = {
    alb = {
      zone_id = data.aws_route53_zone.this.zone_id
      name    = data.aws_route53_zone.this.name
      type    = "A"
      alias = {
        name                   = data.aws_route53_zone.this.name
        zone_id                = data.aws_route53_zone.this.zone_id
        evaluate_target_health = true
      }
    }
  }

  tags = {
    Name = "${local.base_tag}-alb"
  }
}
