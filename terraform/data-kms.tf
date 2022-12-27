data "aws_iam_policy_document" "k3s-kms" {
  for_each = toset(["codebuild", "cw", "ec2", "ecr", "efs", "lambda", "rds", "s3", "sns", "ssm"])

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
      identifiers = [data.aws_caller_identity.k3s.arn]
    }
  }

  ## codebuild statement(s)
  #
  dynamic "statement" {
    for_each = each.value == "codebuild" ? [1] : []
    content {
      sid = "CodebuildUse"
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
        identifiers = ["*"]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.k3s.account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["codebuild.${var.region}.amazonaws.com"]
      }
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
        identifiers = ["logs.${var.region}.amazonaws.com"]
      }
      condition {
        test     = "ArnEquals"
        variable = "kms:EncryptionContext:aws:logs:arn"
        values = [
          "arn:${data.aws_partition.k3s.partition}:logs:${var.region}:${data.aws_caller_identity.k3s.account_id}:log-group:/aws/ec2/${local.prefix}-${local.suffix}",
          "arn:${data.aws_partition.k3s.partition}:logs:${var.region}:${data.aws_caller_identity.k3s.account_id}:log-group:/aws/lambda/${local.prefix}-${local.suffix}-*",
          "arn:${data.aws_partition.k3s.partition}:logs:${var.region}:${data.aws_caller_identity.k3s.account_id}:log-group:/aws/codebuild/${local.prefix}-${local.suffix}-*"
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
        identifiers = [aws_iam_service_linked_role.k3s.arn]
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
        identifiers = [aws_iam_service_linked_role.k3s.arn]
      }
      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }
    }
  }

  dynamic "statement" {
    for_each = each.value == "ec2" ? [1] : []
    content {
      sid = "CSIUse"
      actions = [
        "kms:CreateGrant"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = ["arn:${data.aws_partition.k3s.partition}:iam::${data.aws_caller_identity.k3s.account_id}:root"]
      }
      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }
      condition {
        test     = "Bool"
        variable = "aws:PrincipalArn"
        values   = ["arn:${data.aws_partition.k3s.partition}:iam::${data.aws_caller_identity.k3s.account_id}:role/${local.prefix}-${local.suffix}-aws-ebs-csi-driver"]
      }
    }
  }

  ## ecr statement(s)
  dynamic "statement" {
    for_each = each.value == "ecr" ? [1] : []
    content {
      sid = "EcrUse"
      actions = [
        "kms:CreateGrant",
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = ["arn:${data.aws_partition.k3s.partition}:iam::${data.aws_caller_identity.k3s.account_id}:root"]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.k3s.account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["ecr.${var.region}.amazonaws.com"]
      }
    }
  }

  ## efs statement(s)
  dynamic "statement" {
    for_each = each.value == "efs" ? [1] : []
    content {
      sid = "EfsUse"
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
        identifiers = [aws_iam_role.k3s-ec2-controlplane.arn, aws_iam_role.k3s-ec2-nodes.arn]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.k3s.account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["efs.${var.region}.amazonaws.com"]
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
        "kms:Decrypt"
      ]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = [aws_iam_role.k3s-lambda-getfiles.arn, aws_iam_role.k3s-lambda-oidcprovider.arn]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:CallerAccount"
        values   = [data.aws_caller_identity.k3s.account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:ViaService"
        values   = ["lambda.${var.region}.amazonaws.com"]
      }
    }
  }

  ## sns statement(s)
  #
  dynamic "statement" {
    for_each = each.value == "sns" ? [1] : []
    content {
      sid = "snsallow"
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
        identifiers = [aws_iam_role.k3s-scaledown.arn]
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
        identifiers = [aws_iam_role.k3s-ec2-controlplane.arn, aws_iam_role.k3s-ec2-nodes.arn]
      }
    }
  }

  ## s3 statement(s)
  #
  dynamic "statement" {
    for_each = each.value == "s3" ? [1] : []
    content {
      sid = "CodebuildCodepipelineEC2LambdaAllow"
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
        identifiers = [aws_iam_role.k3s-ec2-controlplane.arn, aws_iam_role.k3s-ec2-nodes.arn, aws_iam_role.k3s-lambda-getfiles.arn, aws_iam_role.k3s-lambda-oidcprovider.arn, aws_iam_role.k3s-codebuild.arn, aws_iam_role.k3s-codepipeline.arn]
      }
    }
  }

}
