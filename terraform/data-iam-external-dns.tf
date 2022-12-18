data "aws_iam_policy_document" "k3s-external-dns-trust" {
  for_each = var.nat_gateways ? { external-dns = true } : {}
  statement {
    sid = "ForAwsCloudControllerManager"
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
      values   = ["system:serviceaccount:kube-system:external-dns"] # system:serviceaccount:namespace:serviceaccountname
    }
  }
}

data "aws_iam_policy_document" "k3s-external-dns" {
  for_each = var.nat_gateways ? { external-dns = true } : {}
  statement {
    sid = "r53list"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "r53change"
    actions = [
      "route53:ChangeResourceRecordSets",
    ]
    effect    = "Allow"
    resources = [aws_route53_zone.k3s.arn]
  }
}
