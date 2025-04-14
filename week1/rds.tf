resource "random_password" "password" {
  length = 8
}

resource "aws_security_group" "rds_sg" {
  name   = "${local.base_tag}-rds-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_sg.id]
  }

  tags = {
    Name = "${local.base_tag}-rds-sg"
  }
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${local.base_tag}-rds"

  engine               = "mysql"
  family               = "mysql8.0"
  engine_version       = "8.0"
  major_engine_version = "8.0"
  instance_class       = var.db_instance_type
  allocated_storage    = var.allocated_storage

  db_name                     = var.db_name
  username                    = var.db_username
  password                    = random_password.password.result
  port                        = 3306
  manage_master_user_password = false
  tags = {
    Name = "${local.base_tag}-rds"
  }

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az                = true
  create_db_subnet_group  = false
  db_subnet_group_name    = aws_db_subnet_group.this.name
  backup_retention_period = 3
  skip_final_snapshot     = true
}
