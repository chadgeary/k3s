data "aws_iam_policy_document" "k3s-aws-lb-controller-trust" {
  statement {
    sid = "ForAWSLBController"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_partition.k3s.partition}:iam::${data.aws_caller_identity.k3s.account_id}:oidc-provider/s3.${var.region}.amazonaws.com/${local.prefix}-${local.suffix}-public/oidc"]
    }
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3.${var.region}.amazonaws.com/${local.prefix}-${local.suffix}-public/oidc:sub"
      values   = ["system:serviceaccount:kube-system:aws-lb-controller"] # system:serviceaccount:namespace:serviceaccountname
    }
  }
}
