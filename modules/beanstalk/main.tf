data "aws_elastic_beanstalk_solution_stack" "php" {
  most_recent = true
  name_regex  = "PHP"
}

data "aws_vpc" "this" {
  default = true
}

data "aws_subnet" "subnet_a" {
  vpc_id            = data.aws_vpc.this.id
  availability_zone = "${var.region}a"
}

data "aws_subnet" "subnet_b" {
  vpc_id            = data.aws_vpc.this.id
  availability_zone = "${var.region}b"
}

data "aws_subnet" "subnet_c" {
  vpc_id            = data.aws_vpc.this.id
  availability_zone = "${var.region}c"
}

resource "aws_elastic_beanstalk_application" "this" {
  name = var.application_name
}

resource "aws_elastic_beanstalk_environment" "this" {
  name                = var.environment_name
  application         = aws_elastic_beanstalk_application.this.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.php.name
  version_label       = aws_elastic_beanstalk_application_version.this.name


  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ec2_profile.name
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = data.aws_subnet.subnet_a.id
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
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_USER"
    value     = module.rds.db_instance_username
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_PASSWORD"
    value     = random_password.password.result
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_HOST"
    value     = split(":", module.rds.db_instance_endpoint)[0]
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DB_NAME"
    value     = module.rds.db_instance_name
  }
}

resource "aws_elastic_beanstalk_application_version" "this" {
  name        = "v1"
  bucket      = aws_s3_bucket.this.bucket
  key         = aws_s3_object.app.key
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

data "archive_file" "name" {
  type        = "zip"
  source_dir  = "${path.module}/src/app"
  output_path = "${path.module}/src/app.zip"
}

resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.this.bucket
  key    = "app.zip"
  source = "${path.module}/src/app.zip"
}

resource "aws_s3_object" "creds" {
  bucket = aws_s3_bucket.this.bucket
  key    = "creds.json"
  content = jsonencode({
    username = module.rds.db_instance_username
    password = random_password.password.result
    host     = split(":", module.rds.db_instance_endpoint)[0]
    db_name  = module.rds.db_instance_name
  })
}

resource "aws_ssm_parameter" "user" {
  name  = "DB_USER"
  type  = "String"
  value = module.rds.db_instance_username
}

resource "aws_ssm_parameter" "password" {
  name  = "DB_PASSWORD"
  type  = "SecureString"
  value = random_password.password.result
}

resource "aws_ssm_parameter" "host" {
  name  = "DB_HOST"
  type  = "String"
  value = split(":", module.rds.db_instance_endpoint)[0]
}

