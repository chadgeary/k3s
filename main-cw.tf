resource "aws_cloudwatch_log_group" "cloudk3s" {
  name              = "/aws/ec2/${local.prefix}-${local.suffix}"
  retention_in_days = var.instances.log_retention_in_days
  kms_key_id        = aws_kms_key.cloudk3s["cw"].arn
  tags = {
    Name = "/aws/ec2/${local.prefix}-${local.suffix}"
  }
}
