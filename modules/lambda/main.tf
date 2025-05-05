data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "random_string" "bucket_suffix" {
  length  = 10
  special = false
  upper   = false
}

resource "aws_s3_bucket" "lambda" {
  bucket = "${var.base_tag}-${random_string.bucket_suffix.result}"

  tags = {
    Name = "${var.base_tag}-bucket"
  }
}

resource "aws_s3_object" "endpoints" {
  bucket = aws_s3_bucket.lambda.bucket
  key    = "endpoints.txt"
  source = "${path.module}/src/endpoints.txt"
}

resource "aws_s3_object" "counts" {
  bucket = aws_s3_bucket.lambda.bucket
  key    = "counts.json"
  source = "${path.module}/src/counts.json"
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.lambda.arn
}

resource "aws_cloudwatch_log_group" "health_check_logs" {
  name              = "/aws/lambda/health_check"
  retention_in_days = 1
}

resource "aws_cloudwatch_event_rule" "interval_minutes" {
  name                = "interval_minutes"
  schedule_expression = "rate(${var.interval_minutes} minutes)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda_every_five_minutes" {
  rule      = aws_cloudwatch_event_rule.interval_minutes.name
  target_id = "health_check_lambda"
  arn       = aws_lambda_function.health_check.arn
}

resource "aws_lambda_permission" "cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.interval_minutes.arn
}

resource "aws_security_group" "lambda_sg" {
  name   = "${var.base_tag}-lambda-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "archive_file" "script" {
  type        = "zip"
  source_file = "${path.module}/src/health_check.py"
  output_path = "${path.module}/src/health_check.zip"
}

resource "aws_lambda_function" "health_check" {
  function_name = "health_check"
  runtime       = "python3.12"
  handler       = "health_check.lambda_handler"
  layers        = [aws_lambda_layer_version.dependencies.arn]
  role          = aws_iam_role.lambda_role.arn
  timeout       = 10
  memory_size   = 128
  # s3_bucket     = aws_s3_bucket.lambda.bucket
  # s3_key        = "health_check.py"
  filename = "${path.module}/src/health_check.zip"
  vpc_config {
    subnet_ids         = [for subnet in var.private_subnet_ids : subnet]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      SNS_TOPIC_ARN  = aws_sns_topic.health_check_notifications.arn
      S3_BUCKET_NAME = aws_s3_bucket.lambda.bucket
    }
  }
}

resource "aws_lambda_layer_version" "dependencies" {
  layer_name          = "health-check-dependencies"
  filename            = "${path.module}/src/lambda_layer.zip"
  compatible_runtimes = ["python3.12"]
}
