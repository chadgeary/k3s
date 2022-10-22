data "aws_iam_policy_document" "k3s-s3-private" {

  statement {
    sid = "CreatorAdmin"
    actions = [
      "s3:*"
    ]
    resources = [aws_s3_bucket.k3s-private.arn]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.k3s.arn]
    }
  }

  statement {
    sid    = "InstanceGet"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      aws_s3_bucket.k3s-private.arn,
      "${aws_s3_bucket.k3s-private.arn}/data/*",
      "${aws_s3_bucket.k3s-private.arn}/scripts/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.k3s-ec2.arn]
    }
  }

  statement {
    sid    = "InstancePut"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.k3s-private.arn}/data/*",
      "${aws_s3_bucket.k3s-private.arn}/oidc/*",
      "${aws_s3_bucket.k3s-private.arn}/ssm/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.k3s-ec2.arn]
    }
  }

  statement {
    sid    = "LambdaPutGetK3s"
    effect = "Allow"
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
    resources = [
      aws_s3_bucket.k3s-private.arn,
      "${aws_s3_bucket.k3s-private.arn}/data/*",
      "${aws_s3_bucket.k3s-private.arn}/scripts/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.k3s-lambda-getk3s.arn]
    }
  }

  statement {
    sid    = "LambdaGetOidcProvider"
    effect = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:GetObjectAcl",
    ]
    resources = [
      aws_s3_bucket.k3s-private.arn,
      "${aws_s3_bucket.k3s-private.arn}/oidc/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.k3s-lambda-oidcprovider.arn]
    }
  }

}

data "aws_iam_policy_document" "k3s-s3-public" {

  statement {
    sid = "CreatorAdmin"
    actions = [
      "s3:*"
    ]
    resources = [aws_s3_bucket.k3s-public.arn]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.k3s.arn]
    }
  }

  statement {
    sid    = "LambdaPutOidcProvider"
    effect = "Allow"
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
    resources = [
      aws_s3_bucket.k3s-public.arn,
      "${aws_s3_bucket.k3s-public.arn}/oidc/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.k3s-lambda-oidcprovider.arn]
    }
  }

  statement {
    sid = "PublicRead"
    actions = [
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.k3s-public.arn}/oidc/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid    = "PublicDeny"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    not_resources = ["${aws_s3_bucket.k3s-public.arn}/oidc/*"]
    not_principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.k3s.arn, aws_iam_role.k3s-lambda-oidcprovider.arn]
    }
  }

}
