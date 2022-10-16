data "aws_iam_policy_document" "cloudk3s-s3" {

  statement {
    sid = "CreatorAdmin"
    actions = [
      "s3:*"
    ]
    resources = [aws_s3_bucket.cloudk3s.arn]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.cloudk3s.arn]
    }
  }

  statement {
    sid    = "Instance Get"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion"
    ]
    resources = [
      aws_s3_bucket.cloudk3s.arn,
      "${aws_s3_bucket.cloudk3s.arn}/data/*",
      "${aws_s3_bucket.cloudk3s.arn}/scripts/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cloudk3s-ec2.arn]
    }
  }

  statement {
    sid    = "Instance Put"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.cloudk3s.arn}/data/*",
      "${aws_s3_bucket.cloudk3s.arn}/ssm/*",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cloudk3s-ec2.arn]
    }
  }

  statement {
    sid    = "Lambda Put"
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
      aws_s3_bucket.cloudk3s.arn,
      "${aws_s3_bucket.cloudk3s.arn}/data/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.cloudk3s-lambda-getk3s.arn]
    }
  }

}
