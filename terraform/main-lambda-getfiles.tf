data "archive_file" "k3s-getk3s" {
  type        = "zip"
  source_file = "main-lambda-getfiles.py"
  output_path = "main-lambda-getfiles.zip"
}

resource "aws_lambda_function" "k3s-getk3s" {
  filename         = "main-lambda-getfiles.zip"
  source_code_hash = data.archive_file.k3s-getk3s.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-getk3s"
  role             = aws_iam_role.k3s-lambda-getfiles.arn
  kms_key_arn      = aws_kms_key.k3s["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-getfiles.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900
  environment {
    variables = {
      BUCKET = aws_s3_bucket.k3s-private.id
      REGION = var.region
      KEY    = aws_kms_key.k3s["s3"].arn
    }
  }
  depends_on = [aws_cloudwatch_log_group.k3s-lambda-getfiles]
}

# invoke per var.lambda_to_s3
data "aws_lambda_invocation" "k3s-getk3s" {
  for_each      = var.lambda_to_s3
  function_name = aws_lambda_function.k3s-getk3s.function_name
  input         = <<JSON
{
 "url": "${each.value.url}",
 "prefix": "${each.value.prefix}"
}
JSON
  depends_on = [
    aws_iam_role_policy_attachment.k3s-lambda-getfiles,
    aws_iam_role_policy_attachment.k3s-lambda-getfiles-managed-1,
    aws_iam_role_policy_attachment.k3s-lambda-getfiles-managed-2
  ]
}
