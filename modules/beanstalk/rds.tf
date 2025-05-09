resource "random_password" "password" {
  length  = 8
  special = false
}

resource "aws_security_group" "rds_sg" {
  name   = "${var.base_tag}-rds-sg"
  vpc_id = data.aws_vpc.this.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  tags = {
    Name = "${var.base_tag}-rds-sg"
  }
}

module "rds" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.base_tag}-rds"

  engine               = "mysql"
  family               = "mysql8.0"
  engine_version       = "8.0"
  major_engine_version = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = "20"

  db_name                     = var.db_name
  username                    = var.db_username
  password                    = random_password.password.result
  port                        = 3306
  manage_master_user_password = false
  tags = {
    Name = "${var.base_tag}-rds"
  }

  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  multi_az                = false
  create_db_subnet_group  = true
  subnet_ids              = [data.aws_subnet.subnet_b.id, data.aws_subnet.subnet_c.id]
  backup_retention_period = 3
  skip_final_snapshot     = true
}
