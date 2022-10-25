data "aws_iam_policy_document" "k3s-awsvpccni-trust" {
  statement {
    sid = "Forawsvpccni"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = ["arn:${data.aws_partition.k3s.partition}:iam::${data.aws_caller_identity.k3s.account_id}:oidc-provider/s3.${var.aws_region}.amazonaws.com/${local.prefix}-${local.suffix}-public/oidc"]
    }
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3.${var.aws_region}.amazonaws.com/${local.prefix}-${local.suffix}-public/oidc:sub"
      values   = ["system:serviceaccount:kube-system:awsvpccni"] # system:serviceaccount:namespace:serviceaccountname
    }
  }
}

data "aws_iam_policy_document" "k3s-awsvpccni" {

  statement {
    sid = "ec2Describe"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstanceTypes"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "ec2ManageENItags"
    actions = [
      "ec2:CreateTags",
      "ec2:CreateNetworkInterface"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:ec2:*:*:network-interface/*"]
  }

  statement {
    sid = "ec2CreateENIsByTag"
    actions = [
      "ec2:CreateNetworkInterface"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:ec2:*:*:network-interface/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/cluster.k8s.amazonaws.com/name"
      values   = ["${local.prefix}-${local.suffix}"]
    }
  }

  statement {
    sid = "ec2ManageENIsByVPC"
    actions = [
      "ec2:CreateNetworkInterface"
    ]
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.k3s.partition}:ec2:*:*:subnet/*",
      "arn:${data.aws_partition.k3s.partition}:ec2:*:*:security-group/*"
    ]
    condition {
      test     = "ArnEquals"
      variable = "ec2:Vpc"
      values   = [aws_vpc.k3s.arn]
    }
  }

  statement {
    sid = "ec2ManageENIsByTag"
    actions = [
      "ec2:DeleteNetworkInterface",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:AssignPrivateIpAddresses",
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:ec2:*:*:network-interface/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/cluster.k8s.amazonaws.com/name"
      values   = ["${local.prefix}-${local.suffix}"]
    }
  }

  statement {
    sid = "ec2AttachENIsByTag"
    actions = [
      "ec2:AttachNetworkInterface",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:ec2:*:*:network-interface/*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${local.prefix}-${local.suffix}"
      values   = ["owned"]
    }
  }

  statement {
    sid = "ec2ENISGs"
    actions = [
      "ec2:ModifyNetworkInterfaceAttribute"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:ec2:*:*:security-group/*"]
  }

}
