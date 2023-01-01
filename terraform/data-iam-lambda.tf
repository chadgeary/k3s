data "aws_iam_policy" "k3s-lambda-getfiles-managed-1" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "k3s-lambda-getfiles-managed-2" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "k3s-lambda-getfiles-trust" {
  statement {
    sid = "ForLambdaOnly"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "k3s-lambda-getfiles" {

  statement {
    sid = "ListBucket"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.k3s-private.arn,
      "${aws_s3_bucket.k3s-private.arn}/data/*",
      "${aws_s3_bucket.k3s-private.arn}/scripts/*"
    ]
  }

  statement {
    sid = "UseKMSLambda"
    actions = [
      "kms:Decrypt"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["lambda"].arn]
  }

  statement {
    sid = "UseKMSS3"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["s3"].arn]
  }

}

data "aws_iam_policy" "k3s-lambda-oidcprovider-managed-1" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "k3s-lambda-oidcprovider-managed-2" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "k3s-lambda-oidcprovider-trust" {
  statement {
    sid = "ForLambdaOnly"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "k3s-lambda-oidcprovider" {

  statement {
    sid = "ListBucket"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:GetObject",
      "s3:GetObjectAcl",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.k3s-private.arn,
      "${aws_s3_bucket.k3s-private.arn}/oidc/*",
    ]
  }

  statement {
    sid = "PutBucket"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:PutObjectTagging",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.k3s-public.arn,
      "${aws_s3_bucket.k3s-public.arn}/oidc/*",
    ]
  }

  statement {
    sid = "UseKMSLambda"
    actions = [
      "kms:Decrypt"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["lambda"].arn]
  }

  statement {
    sid = "UseKMSS3"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["s3"].arn]
  }

  statement {
    sid = "ManageOIDCProvider"
    actions = [
      "iam:CreateOpenIDConnectProvider",
      "iam:UpdateOpenIDConnectProviderThumbprint",
      "iam:TagOpenIDConnectProvider",
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:iam::${data.aws_caller_identity.k3s.account_id}:oidc-provider/s3.${var.region}.amazonaws.com*"]
  }
}

data "aws_iam_policy" "k3s-lambda-scaledown-managed-1" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "k3s-lambda-scaledown-managed-2" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "k3s-lambda-scaledown-trust" {
  statement {
    sid = "ForLambdaOnly"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "k3s-lambda-scaledown" {

  statement {
    sid = "UseKMSLambda"
    actions = [
      "kms:Decrypt"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["lambda"].arn]
  }

  statement {
    sid = "Autoscaledown"
    actions = [
      "autoscaledown:CompleteLifecycleAction"
    ]
    effect    = "Allow"
    resources = [for asg in aws_autoscaling_group.k3s : asg.arn]
  }

  statement {
    sid = "KMSList"
    actions = [
      "kms:ListKeys"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy" "k3s-lambda-r53updater-managed-1" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "k3s-lambda-r53updater-managed-2" {
  arn = "arn:${data.aws_partition.k3s.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "k3s-lambda-r53updater-trust" {
  statement {
    sid = "ForLambdaOnly"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "k3s-lambda-r53updater" {

  statement {
    sid = "UseKMSLambda"
    actions = [
      "kms:Decrypt"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["lambda"].arn]
  }

  statement {
    sid = "ASG"
    actions = [
      "autoscaling:DescribeAutoScalingGroups"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "EC2"
    actions = [
      "ec2:DescribeInstances"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "SSMKMS"
    actions = [
      "kms:GenerateDataKey*",
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["ssm"].arn]
  }

  statement {
    sid = "R53"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    effect    = "Allow"
    resources = [aws_route53_zone.k3s.arn]
  }

  statement {
    sid = "SSM"
    actions = [
      "ssm:PutParameter",
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:ssm:${var.region}:${data.aws_caller_identity.k3s.account_id}:parameter/${local.prefix}-${local.suffix}/FIRST_INSTANCE_ID"]
  }

}
