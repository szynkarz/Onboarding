resource "aws_sns_topic" "health_check_notifications" {
  name = "health-check-notifications"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.health_check_notifications.arn
  protocol  = "email"
  endpoint  = "arseniishynkaruk@gmail.com"
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.health_check.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.health_check_notifications.arn
}
