output "application_url" {
  value = "http://${aws_elastic_beanstalk_environment.this.endpoint_url}"
}

output "environment_id" {
  value = aws_elastic_beanstalk_environment.this.id
}
