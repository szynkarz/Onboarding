data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group" "asg_sg" {
  name   = "${var.base_tag}-asg-sg"
  vpc_id = var.vpc_id

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

  ingress {
    from_port   = 5044
    to_port     = 5044
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.base_tag}-asg-sg"
  }
}

resource "aws_launch_template" "lt" {
  name                   = "${var.base_tag}-lt"
  image_id               = data.aws_ami.al2.image_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  update_default_version = true
  iam_instance_profile {
    name = aws_iam_instance_profile.wordpress_profile.name
  }
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
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
  vpc_zone_identifier = [for subnet in var.private_subnet_ids : subnet]
  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
  target_group_arns         = [aws_lb_target_group.asg.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300

}


