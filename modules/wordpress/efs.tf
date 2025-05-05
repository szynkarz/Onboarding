resource "aws_security_group" "efs_sg" {
  name   = "${var.base_tag}-efs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
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
    Name = "${var.base_tag}-efs-sg"
  }
}

resource "aws_efs_file_system" "efs" {
  creation_token = "${var.base_tag}-efs"
  encrypted      = true

  tags = {
    Name = "${var.base_tag}-efs"
  }
}

resource "aws_efs_mount_target" "mt" {
  for_each = { for idx, subnet in var.private_subnet_ids : idx => subnet }

  file_system_id  = aws_efs_file_system.efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sg.id]
}

