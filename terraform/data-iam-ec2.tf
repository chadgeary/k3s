data "aws_iam_policy_document" "k3s-ec2-passrole" {
  statement {
    sid = "AdminPassRole"
    actions = [
      "iam:PassRole"
    ]
    effect    = "Allow"
    resources = [aws_iam_service_linked_role.k3s.arn]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["autoscaling.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "iam:AssociatedResourceArn"
      values   = ["arn:${data.aws_partition.k3s.partition}:autoscaling:${var.region}:autoScalingGroup:*:autoScalingGroupName/${local.prefix}-${local.suffix}"]
    }
  }
}

data "aws_iam_policy" "k3s-ec2-managed" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "k3s-ec2-trust" {
  statement {
    sid = "ForEc2Only"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "k3s-ec2" {

  statement {
    sid = "ListBucket"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.k3s-private.arn]
  }

  statement {
    sid = "GetBucketObjects"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging"
    ]
    effect    = "Allow"
    resources = [aws_s3_bucket.k3s-private.arn, "${aws_s3_bucket.k3s-private.arn}/*"]
  }

  statement {
    sid = "PutBucketObjects"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.k3s-private.arn}/ssm/*",
      "${aws_s3_bucket.k3s-private.arn}/data/*"
    ]
  }

  statement {
    sid = "UseKMS"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["s3"].arn, aws_kms_key.k3s["ssm"].arn]
  }

  statement {
    sid = "UseCloudwatch"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = [aws_cloudwatch_log_group.k3s-ec2.arn]
  }

  statement {
    sid = "UseECR"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:BatchImportUpstreamImage",
      "ecr:CreateRepository",
      "ecr:DescribeImages",
      "ecr:DescribeImageScanFindings",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRepositoryPolicy",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "cloudprovider"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchGetImage"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

}
