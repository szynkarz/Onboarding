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

  identifier = "demodb"

  engine            = "mysql"
  family            = "mysql5.7"
  engine_version    = "5.7"
  instance_class    = var.db_instance_type
  allocated_storage = var.allocated_storage

  #   db_name  = "demodb"
  #   username = "user"
  #   port     = "3306"

  #  vpc_security_group_ids = ["sg-12345678"]

  tags = {
    Name = "${local.base_tag}-rds"
  }

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  multi_az                = true
  create_db_subnet_group  = true
  subnet_ids              = [for subnet in aws_subnet.rds_subnet : subnet.id]
  backup_retention_period = 3
}
