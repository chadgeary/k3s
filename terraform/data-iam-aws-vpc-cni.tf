data "aws_iam_policy_document" "k3s-aws-vpc-cni-trust" {
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
      values   = ["system:serviceaccount:kube-system:aws-vpc-cni"] # system:serviceaccount:namespace:serviceaccountname
    }
  }
}

data "aws_iam_policy_document" "k3s-aws-vpc-cni" {

  statement {
    sid = "cloudprovider"
    actions = [
      "ec2:AssignPrivateIpAddresses",
      "ec2:AttachNetworkInterface",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeInstanceTypes",
      "ec2:DetachNetworkInterface",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:UnassignPrivateIpAddresses"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

}
