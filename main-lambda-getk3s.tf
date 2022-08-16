data "archive_file" "cloudk3s-getk3s" {
  type        = "zip"
  source_file = "main-lambda-getk3s.py"
  output_path = "main-lambda-getk3s.zip"
}

resource "aws_lambda_function" "cloudk3s-getk3s" {
  filename         = "main-lambda-getk3s.zip"
  source_code_hash = data.archive_file.cloudk3s-getk3s.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-getk3s"
  role             = aws_iam_role.cloudk3s-lambda-getk3s.arn
  kms_key_arn      = aws_kms_key.cloudk3s["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-getk3s.lambda_handler"
  runtime          = "python3.7"
  timeout          = 600
  environment {
    variables = {
      K3S_BIN_URL = var.urls.k3s_bin
      K3S_TAR_URL = var.urls.k3s_tar
      BUCKET      = aws_s3_bucket.cloudk3s.id
      REGION      = var.aws_region
      KEY         = aws_kms_key.cloudk3s["s3"].arn
    }
  }
  depends_on = [aws_cloudwatch_log_group.cloudk3s-lambda-getk3s]
}

data "aws_lambda_invocation" "cloudk3s-getk3s" {
  function_name = aws_lambda_function.cloudk3s-getk3s.function_name
  input         = <<JSON
{
 "terraform": "terraform"
}
JSON
  depends_on    = [aws_cloudwatch_log_group.cloudk3s-lambda-getk3s]
}
