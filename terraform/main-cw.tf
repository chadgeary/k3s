resource "aws_cloudwatch_log_group" "k3s-ec2" {
  name              = "/aws/ec2/${local.prefix}-${local.suffix}"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.k3s["cw"].arn
  tags = {
    Name = "/aws/ec2/${local.prefix}-${local.suffix}"
  }
}

resource "aws_cloudwatch_log_group" "k3s-lambda-getk3s" {
  name              = "/aws/lambda/${local.prefix}-${local.suffix}-getk3s"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.k3s["cw"].arn
  tags = {
    Name = "/aws/lambda/${local.prefix}-${local.suffix}-getk3s"
  }
}

resource "aws_cloudwatch_log_group" "k3s-lambda-oidcprovider" {
  name              = "/aws/lambda/${local.prefix}-${local.suffix}-oidcprovider"
  retention_in_days = var.log_retention_in_days
  kms_key_id        = aws_kms_key.k3s["cw"].arn
  tags = {
    Name = "/aws/lambda/${local.prefix}-${local.suffix}-oidcprovider"
  }
}
