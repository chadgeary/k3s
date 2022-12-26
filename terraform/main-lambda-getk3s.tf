data "archive_file" "k3s-getk3s" {
  type        = "zip"
  source_file = "main-lambda-getk3s.py"
  output_path = "main-lambda-getk3s.zip"
}

resource "aws_lambda_function" "k3s-getk3s" {
  filename         = "main-lambda-getk3s.zip"
  source_code_hash = data.archive_file.k3s-getk3s.output_base64sha256
  function_name    = "${local.prefix}-${local.suffix}-getk3s"
  role             = aws_iam_role.k3s-lambda-getk3s.arn
  kms_key_arn      = aws_kms_key.k3s["lambda"].arn
  memory_size      = 256
  handler          = "main-lambda-getk3s.lambda_handler"
  runtime          = "python3.9"
  timeout          = 900
  environment {
    variables = {
      AWSCLIV2_X86_64      = var.urls.AWSCLIV2_X86_64
      AWSCLIV2_ARM64       = var.urls.AWSCLIV2_ARM64
      AWS_CLOUD_CONTROLLER = var.urls.AWS_CLOUD_CONTROLLER
      AWS_EBS_CSI_DRIVER   = var.urls.AWS_EBS_CSI_DRIVER
      AWS_EFS_CSI_DRIVER   = var.urls.AWS_EFS_CSI_DRIVER
      CILIUM               = var.urls.CILIUM
      EXTERNAL_DNS         = var.urls.EXTERNAL_DNS
      HELM_ARM64           = var.urls.HELM_ARM64
      HELM_X86_64          = var.urls.HELM_X86_64
      K3S_INSTALL          = var.urls.K3S_INSTALL
      K3S_BIN_ARM64        = var.urls.K3S_BIN_ARM64
      K3S_BIN_X86_64       = var.urls.K3S_BIN_X86_64
      K3S_TAR_ARM64        = var.urls.K3S_TAR_ARM64
      K3S_TAR_X86_64       = var.urls.K3S_TAR_X86_64
      UNZIP_ARM64          = var.urls.UNZIP_ARM64
      UNZIP_X86_64         = var.urls.UNZIP_X86_64
      BUCKET               = aws_s3_bucket.k3s-private.id
      REGION               = var.region
      KEY                  = aws_kms_key.k3s["s3"].arn
    }
  }
  depends_on = [aws_cloudwatch_log_group.k3s-lambda-getk3s]
}

# split downloads across three lambda invocations
data "aws_lambda_invocation" "k3s-getk3s" {
  for_each      = toset(["k3s-bin", "k3s-arm64", "k3s-x86_64", "k3s-charts"])
  function_name = aws_lambda_function.k3s-getk3s.function_name
  input         = <<JSON
{
 "invoker":"${each.key}"
}
JSON
  depends_on = [
    aws_iam_role_policy_attachment.k3s-lambda-getk3s,
    aws_iam_role_policy_attachment.k3s-lambda-getk3s-managed-1,
    aws_iam_role_policy_attachment.k3s-lambda-getk3s-managed-2
  ]
}
