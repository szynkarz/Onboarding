resource "aws_security_group" "asg_sg" {
  name   = "${local.base_tag}-asg-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_iam_role" "ec2_efs_role" {
  name = "${local.base_tag}-ec2-efs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.base_tag}-ec2-efs-role"
  }
}

resource "aws_iam_policy" "efs_access_policy" {
  name        = "${local.base_tag}-efs-access-policy"
  description = "Policy allowing EC2 instances to access EFS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess",
          "elasticfilesystem:DescribeFileSystems"
        ]
        Resource = aws_efs_file_system.efs.arn
      }
    ]
  })

  tags = {
    Name = "${local.base_tag}-efs-access-policy"
  }
}

resource "aws_iam_role_policy_attachment" "efs_policy_attachment" {
  role       = aws_iam_role.ec2_efs_role.name
  policy_arn = aws_iam_policy.efs_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_efs_profile" {
  name = "${local.base_tag}-ec2-efs-profile"
  role = aws_iam_role.ec2_efs_role.name

  tags = {
    Name = "${local.base_tag}-ec2-efs-profile"
  }
}

resource "aws_launch_template" "lt" {
  name                   = "${local.base_tag}-lt"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  update_default_version = true

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_efs_profile.name
  }
  key_name = var.key_name
  user_data = base64encode(templatefile("user_data.sh", {
    DB_NAME     = module.rds.db_instance_name
    DB_USER     = module.rds.db_instance_username
    DB_PASSWORD = random_password.password.result
    MYSQL_HOST  = split(":", module.rds.db_instance_endpoint)[0]
    EFS         = aws_efs_file_system.efs.dns_name
  }))
  vpc_security_group_ids = [aws_security_group.asg_sg.id]
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
  health_check_grace_period = 300

}


