data "aws_iam_policy_document" "k3s-codepipeline-trust" {
  statement {
    sid = "ForCodepipeOnly"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "k3s-codepipeline" {

  statement {
    sid = "UseS3"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.k3s-private.arn,
      "${aws_s3_bucket.k3s-private.arn}/containers*"
    ]
  }

  statement {
    sid = "UseKMS"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["codebuild"].arn, aws_kms_key.k3s["s3"].arn]
  }

  statement {
    sid = "UseCodebuild"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    effect    = "Allow"
    resources = [for project in aws_codebuild_project.k3s : project.arn]
  }

  statement {
    sid = "PassToService"
    actions = [
      "iam:PassRole"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:iam::${var.region}:role/${local.prefix}-${local.suffix}-codepipeline"]
    condition {
      test     = "StringEqualsIfExists"
      variable = "iam:PassedToService"
      values   = ["codepipeline.amazonaws.com"]
    }
  }
}
