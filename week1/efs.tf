resource "aws_security_group" "efs_sg" {
  name   = "${local.base_tag}-efs-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.asg_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.base_tag}-efs-sg"
  }
}

resource "aws_efs_file_system" "this" {
  creation_token = "${local.base_tag}-efs"
  encrypted      = true

  tags = {
    Name = "${local.base_tag}-efs"
  }
}

resource "aws_efs_mount_target" "this" {
  for_each = { for idx, az in var.az_list : idx => az }

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = aws_subnet.asg_subnet[each.key].id
  security_groups = [aws_security_group.efs_sg.id]
}

