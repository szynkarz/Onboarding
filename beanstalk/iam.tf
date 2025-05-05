resource "aws_iam_role" "beanstalk_role" {
  name = "beanstalk_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "elasticbeanstalk.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy" "rds_policy" {
  name = "AWSElasticBeanstalkRoleRDS"
}

resource "aws_iam_policy" "beanstalk_policy" {
  name = "beanstalk_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ec2:DescribeNetworkInterfaces",
          "ec2:CreateNetworkInterface",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.this.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.this.bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "beanstalk_policy_attachment" {
  policy_arn = aws_iam_policy.beanstalk_policy.arn
  role       = aws_iam_role.beanstalk_role.name
}

resource "aws_iam_role_policy_attachment" "rds_policy_attachment" {
  policy_arn = data.aws_iam_policy.rds_policy.arn
  role       = aws_iam_role.beanstalk_role.name
}
