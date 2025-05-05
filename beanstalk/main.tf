data "aws_elastic_beanstalk_solution_stack" "php" {
  most_recent = true
  name_regex  = "PHP"
}

data "aws_vpc" "this" {
  default = true
}

data "aws_subnet" "this" {
  vpc_id            = data.aws_vpc.this.id
  availability_zone = "${var.region}a"
}

resource "aws_elastic_beanstalk_application" "this" {
  name = var.application_name
}

resource "aws_elastic_beanstalk_environment" "this" {
  depends_on          = [aws_elastic_beanstalk_application.this]
  name                = var.environment_name
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.php.name

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = data.aws_subnet.this.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "DBSubnets"
    value     = data.aws_subnet.this.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.beanstalk_role.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "EC2KeyName"
    value     = var.key_name
  }

  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBInstanceClass"
    value     = "db.t3.micro"
  }
  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBEngine"
    value     = "mysql"
  }
  setting {
    namespace = "aws:rds:dbinstance"
    name      = "DBUser"
    value     = "test"
  }
}

resource "aws_elastic_beanstalk_application_version" "this" {
  name        = "v1"
  bucket      = aws_s3_bucket.this.bucket
  key         = aws_s3_object.this.key
  application = aws_elastic_beanstalk_application.this.name
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket" "this" {
  bucket = "beanstalk-${random_string.bucket_suffix.result}"
}
