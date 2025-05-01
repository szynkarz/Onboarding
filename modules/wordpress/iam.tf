resource "aws_iam_role" "ec2_efs_role" {
  name = "${var.base_tag}-ec2-efs-role"

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
    Name = "${var.base_tag}-ec2-efs-role"
  }
}

resource "aws_iam_policy" "efs_access_policy" {
  name        = "${var.base_tag}-efs-access-policy"
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
    Name = "${var.base_tag}-efs-access-policy"
  }
}

resource "aws_iam_role_policy_attachment" "efs_policy_attachment" {
  role       = aws_iam_role.ec2_efs_role.name
  policy_arn = aws_iam_policy.efs_access_policy.arn
}

resource "aws_iam_instance_profile" "ec2_efs_profile" {
  name = "${var.base_tag}-ec2-efs-profile"
  role = aws_iam_role.ec2_efs_role.name

  tags = {
    Name = "${var.base_tag}-ec2-efs-profile"
  }
}
