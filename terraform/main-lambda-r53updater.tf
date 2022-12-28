data "archive_file" "k3s-r53updater" {
  type        = "zip"
  source_file = "main-lambda-r53updater.py"
  output_path = "main-lambda-r53updater.zip"
}

resource "aws_lambda_function" "k3s-r53updater" {
  filename         = "main-lambda-r53updater.zip"
  source_code_hash = data.archive_file.k3s-r53updater.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-r53updater"
  role             = aws_iam_role.k3s-lambda-r53updater.arn
  kms_key_arn      = aws_kms_key.k3s["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-r53updater.lambda_handler"
  runtime          = "python3.9"
  timeout          = 45
  environment {
    variables = {
      PREFIX         = local.prefix
      SUFFIX         = local.suffix
      HOSTED_ZONE_ID = aws_route53_zone.k3s.id
    }
  }
  depends_on = [aws_cloudwatch_log_group.k3s-lambda-r53updater]
}

# allow cw to call lambda
resource "aws_lambda_permission" "k3s-r53updater" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.k3s-r53updater.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.k3s-r53updater.arn
}
