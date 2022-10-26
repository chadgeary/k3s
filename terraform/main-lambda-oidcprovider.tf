data "archive_file" "k3s-oidcprovider" {
  type        = "zip"
  source_file = "main-lambda-oidcprovider.py"
  output_path = "main-lambda-oidcprovider.zip"
}

resource "aws_lambda_function" "k3s-oidcprovider" {
  filename         = "main-lambda-oidcprovider.zip"
  source_code_hash = data.archive_file.k3s-oidcprovider.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-oidcprovider"
  role             = aws_iam_role.k3s-lambda-oidcprovider.arn
  kms_key_arn      = aws_kms_key.k3s["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-oidcprovider.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900
  environment {
    variables = {
      ACCOUNT        = data.aws_caller_identity.k3s.account_id
      BUCKET_PUBLIC  = aws_s3_bucket.k3s-public.id
      BUCKET_PRIVATE = aws_s3_bucket.k3s-private.id
      OBJECT_TIMEOUT = 800
      REGION         = var.region
      PREFIX         = local.prefix
      SUFFIX         = local.suffix
    }
  }
  depends_on = [aws_cloudwatch_log_group.k3s-lambda-oidcprovider, aws_autoscaling_group.k3s["control-plane"]]
}

data "aws_lambda_invocation" "k3s-oidcprovider" {
  function_name = aws_lambda_function.k3s-oidcprovider.function_name
  input         = <<JSON
{
 "caller":"terraform"
}
JSON
  depends_on = [
    aws_iam_role_policy_attachment.k3s-lambda-oidcprovider,
    aws_iam_role_policy_attachment.k3s-lambda-oidcprovider-managed-1,
    aws_iam_role_policy_attachment.k3s-lambda-oidcprovider-managed-2,
  ]
}
