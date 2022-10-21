data "aws_iam_policy_document" "k3s-irsa-trust" {
  statement {
    sid = "ForIrsa"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_partition.k3s.partition}:iam::${data.aws_caller_identity.k3s.account_id}:oidc-provider/${aws_s3_bucket.k3s-public.id}.s3.${var.aws_region}.amazonaws.com/oidc"]
    }
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "${aws_s3_bucket.k3s-public.id}.s3.${var.aws_region}.amazonaws.com/oidc:sub"
      values   = ["system:serviceaccount:foo:bar"] # foo:bar = namespace:serviceaccount
    }
  }
}

data "aws_iam_policy_document" "k3s-irsa" {

  statement {
    sid = "ListBucket"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.k3s-private.arn,
      "${aws_s3_bucket.k3s-private.arn}/foo/*",
    ]
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
