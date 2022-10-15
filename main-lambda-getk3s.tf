data "archive_file" "cloudk3s-getk3s" {
  type        = "zip"
  source_file = "main-lambda-getk3s.py"
  output_path = "main-lambda-getk3s.zip"
}

resource "aws_lambda_function" "cloudk3s-getk3s" {
  for_each         = toset(["arm64", "x86_64"])
  filename         = "main-lambda-getk3s.zip"
  source_code_hash = data.archive_file.cloudk3s-getk3s.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-getk3s-${each.key}"
  role             = aws_iam_role.cloudk3s-lambda-getk3s.arn
  kms_key_arn      = aws_kms_key.cloudk3s["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-getk3s.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900
  architectures    = [each.key]
  environment {
    variables = {
      K3S_BIN_URL_ARM64  = var.urls.k3s_bin-arm64
      K3S_BIN_URL_X86_64 = var.urls.k3s_bin-x86_64
      K3S_TAR_URL_ARM64  = var.urls.k3s_tar-arm64
      K3S_TAR_URL_X86_64 = var.urls.k3s_tar-x86_64
      BUCKET             = aws_s3_bucket.cloudk3s.id
      REGION             = var.aws_region
      KEY                = aws_kms_key.cloudk3s["s3"].arn
    }
  }
  depends_on = [aws_cloudwatch_log_group.cloudk3s-lambda-getk3s]
}

data "aws_lambda_invocation" "cloudk3s-getk3s-k3s-bin" {
  function_name = aws_lambda_function.cloudk3s-getk3s["x86_64"].function_name
  input         = <<JSON
{
 "files":"k3s-bin"
}
JSON
  depends_on    = [aws_cloudwatch_log_group.cloudk3s-lambda-getk3s]
}

data "aws_lambda_invocation" "cloudk3s-getk3s-k3s-arm64" {
  function_name = aws_lambda_function.cloudk3s-getk3s["x86_64"].function_name
  input         = <<JSON
{
 "files":"k3s-arm64"
}
JSON
  depends_on    = [aws_cloudwatch_log_group.cloudk3s-lambda-getk3s]
}

data "aws_lambda_invocation" "cloudk3s-getk3s-k3s-x86_64" {
  function_name = aws_lambda_function.cloudk3s-getk3s["x86_64"].function_name
  input         = <<JSON
{
 "files":"k3s-x86_64"
}
JSON
  depends_on    = [aws_cloudwatch_log_group.cloudk3s-lambda-getk3s]
}

# call via arm and x86 to ensure all packages are downloaded
data "aws_lambda_invocation" "cloudk3s-getk3s-python-arm64" {
  function_name = aws_lambda_function.cloudk3s-getk3s["arm64"].function_name
  input         = <<JSON
{
 "files":"python"
}
JSON
  depends_on    = [aws_cloudwatch_log_group.cloudk3s-lambda-getk3s]
}

data "aws_lambda_invocation" "cloudk3s-getk3s-python-x86_64" {
  function_name = aws_lambda_function.cloudk3s-getk3s["x86_64"].function_name
  input         = <<JSON
{
 "files":"python"
}
JSON
  depends_on    = [aws_cloudwatch_log_group.cloudk3s-lambda-getk3s]
}