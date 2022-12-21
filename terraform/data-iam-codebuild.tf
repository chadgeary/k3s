data "aws_iam_policy_document" "k3s-codebuild-trust" {
  statement {
    sid = "ForCodebuildPipelineOnly"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com", "codepipeline.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "k3s-codebuild" {

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
    sid = "UseCloudwatch"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect = "Allow"
    resources = [
      aws_cloudwatch_log_group.k3s-codebuild.arn,
      "arn:${data.aws_partition.k3s.partition}:logs:${var.region}:${data.aws_caller_identity.k3s.account_id}:log-group:/aws/codebuild/${local.prefix}-${local.suffix}-codebuild*"
    ]
  }

  statement {
    sid = "UseECR"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

}
