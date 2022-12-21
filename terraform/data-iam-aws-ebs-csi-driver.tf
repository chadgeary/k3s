data "aws_iam_policy_document" "k3s-aws-ebs-csi-driver-trust" {
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
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"] # system:serviceaccount:namespace:serviceaccountname
    }
  }
}

data "aws_iam_policy_document" "k3s-aws-ebs-csi-driver" {
  statement {
    sid = "ebsall"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:AttachVolume",
      "ec2:DetachVolume",
      "ec2:ModifyVolume",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "ebstagscreate1"
    actions = [
      "ec2:CreateTags"
    ]
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.k3s.partition}:ec2:*:*:volume/*",
      "arn:${data.aws_partition.k3s.partition}:ec2:*:*:snapshot/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateVolume",
        "CreateSnapshot"
      ]
    }
  }

  statement {
    sid = "ebstagsdelete1"
    actions = [
      "ec2:DeleteTags"
    ]
    effect = "Allow"
    resources = [
      "arn:${data.aws_partition.k3s.partition}:ec2:*:*:volume/*",
      "arn:${data.aws_partition.k3s.partition}:ec2:*:*:snapshot/*"
    ]
  }

  statement {
    sid = "ebsvolcreate1"
    actions = [
      "ec2:CreateVolume"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/ebs.csi.aws.com/cluster"
      values = [
        "true"
      ]
    }
  }

  statement {
    sid = "ebsvolcreate2"
    actions = [
      "ec2:CreateVolume"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/CSIVolumeName"
      values = [
        "*"
      ]
    }
  }

  statement {
    sid = "ebsvoldelete1"
    actions = [
      "ec2:DeleteVolume"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/ebs.csi.aws.com/cluster"
      values = [
        "true"
      ]
    }
  }

  statement {
    sid = "ebsvoldelete2"
    actions = [
      "ec2:DeleteVolume"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeName"
      values = [
        "*"
      ]
    }
  }

  statement {
    sid = "ebsvoldelete3"
    actions = [
      "ec2:DeleteVolume"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/kubernetes.io/created-for/pvc/name"
      values = [
        "*"
      ]
    }
  }

  statement {
    sid = "ebsnapdelete1"
    actions = [
      "ec2:DeleteSnapshot"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/ebs.csi.aws.com/cluster"
      values = [
        "true"
      ]
    }
  }

  statement {
    sid = "ebsnapdelete2"
    actions = [
      "ec2:DeleteSnapshot"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
    condition {
      test     = "StringLike"
      variable = "ec2:ResourceTag/CSIVolumeSnapshotName"
      values = [
        "*"
      ]
    }
  }
}
