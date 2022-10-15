data "aws_iam_policy_document" "cloudk3s-kms" {
  for_each = toset(["cw", "ec2", "lambda", "rds", "s3", "ssm"])

  ## all kms policies statement(s)
  #
  statement {
    sid = "CreatorAdmin"
    actions = [
      "kms:*"
    ]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.cloudk3s.arn]
    }
  }

  ## cloudwatch statement(s)
  #
  dynamic "statement" {
    for_each = each.value == "cw" ? [1] : []
    content {
      sid = "CloudwatchUse"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["logs.${var.aws_region}.amazonaws.com"]
      }
      condition {
        test     = "ArnEquals"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values = [
          "arn:${data.aws_partition.cloudk3s.partition}:logs:${var.aws_region}:${data.aws_caller_identity.cloudk3s.account_id}:log-group:/aws/ec2/${local.prefix}-${local.suffix}",
          "arn:${data.aws_partition.cloudk3s.partition}:logs:${var.aws_region}:${data.aws_caller_identity.cloudk3s.account_id}:log-group:/aws/lambda/${local.prefix}-${local.suffix}-getk3s"
        ]
      }
    }
  }

  ## ec2 statement(s)
  #
  dynamic "statement" {
    for_each = each.value == "ec2" ? [1] : []
    content {
      sid = "AutoscaleUse"
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = [aws_iam_service_linked_role.cloudk3s.arn]
      }
    }
  }

  dynamic "statement" {
    for_each = each.value == "ec2" ? [1] : []
    content {
      sid = "AutoscaleAttach"
      actions = [
        "kms:CreateGrant"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = [aws_iam_service_linked_role.cloudk3s.arn]
      }
      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }
    }
  }

  ## lambda statement(s)
  #
  dynamic "statement" {
    for_each = each.value == "lambda" ? [1] : []
    content {
      sid = "LambdaUse"
      actions = [
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = [aws_iam_role.cloudk3s-lambda-getk3s.arn]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.cloudk3s.account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["lambda.${var.aws_region}.amazonaws.com"]
      }
    }
  }

  ## ssm statement(s)
  #
  dynamic "statement" {
    for_each = each.value == "ssm" ? [1] : []
    content {
      sid = "EC2Allow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = [aws_iam_role.cloudk3s-ec2.arn]
      }
    }
  }

  ## s3 statement(s)
  #
  dynamic "statement" {
    for_each = each.value == "s3" ? [1] : []
    content {
      sid = "EC2LambdaAllow"
      actions = [
        "kms:Decrypt",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = [aws_iam_role.cloudk3s-ec2.arn, aws_iam_role.cloudk3s-lambda-getk3s.arn]
      }
    }
  }

}
