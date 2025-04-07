resource "aws_security_group" "asg_sg" {
  name        = "${local.base_tag}-asg-sg"
  description = "Security group for ASG instances"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.base_tag}-asg-sg"
  }
}

resource "aws_launch_template" "lt" {
  name                 = "${local.base_tag}-lt"
  image_id             = var.ami_id
  instance_type        = var.instance_type
  security_group_names = [aws_security_group.asg_sg.name]
}

# resource "aws_autoscaling_group" "asg" {
#   desired_capacity    = var.asg_desired_capacity
#   max_size            = var.asg_max_size
#   min_size            = var.asg_min_size
#   vpc_zone_identifier = [for subnet in aws_subnet.asg_subnet : subnet.id]

#   launch_template {
#     id = aws_launch_template.lt.id
#   }

#   target_group_arns = [aws_lb_target_group.asg.arn]
#   health_check_type = "EC2"
# }

module "asg" {
  source = "terraform-aws-modules/autoscaling/aws"

  name                 = "${local.base_tag}-asg"
  launch_template_name = aws_launch_template.lt.name

  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  health_check_type   = "EC2"
  vpc_zone_identifier = [for subnet in aws_subnet.asg_subnet : subnet.id]
  enable_monitoring   = true
  force_delete        = true

  # create_iam_instance_profile = true
  # iam_role_name               = "example-asg"
  # iam_role_path               = "/ec2/"
  # iam_role_description        = "IAM role example"
  # iam_role_tags = {
  #   CustomIamRole = "Yes"
  # }
  # iam_role_policies = {
  #   AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  # }

  tags = {
    Name = "${local.base_tag}-asg"
  }
}
