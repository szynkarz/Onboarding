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
  name          = "${local.base_tag}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
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
    id = aws_launch_template.lt.id
  }
  target_group_arns         = [aws_lb_target_group.asg.arn]
  health_check_type         = "EC2"
  health_check_grace_period = 300
}

