data "archive_file" "k3s-scaledown" {
  type        = "zip"
  source_file = "main-lambda-scaledown.py"
  output_path = "main-lambda-scaledown.zip"
}

resource "aws_lambda_function" "k3s-scaledown" {
  filename         = "main-lambda-scaledown.zip"
  source_code_hash = data.archive_file.k3s-scaledown.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-scaledown"
  role             = aws_iam_role.k3s-lambda-scaledown.arn
  kms_key_arn      = aws_kms_key.k3s["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-scaledown.lambda_handler"
  runtime          = "python3.9"
  timeout          = 300
  environment {
    variables = {
      SSMDOCUMENTNAME = aws_ssm_document.k3s-scaledown.name
    }
  }
  depends_on = [aws_cloudwatch_log_group.k3s-lambda-scaledown, aws_autoscaling_group.k3s["control-plane"]]
}

# allow sns to call lambda
resource "aws_lambda_permission" "k3s-scaledown" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.k3s-scaledown.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.k3s-scaledown.arn
}
