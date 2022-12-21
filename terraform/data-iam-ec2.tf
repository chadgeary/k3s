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

data "aws_iam_policy_document" "k3s-ec2-controlplane" {

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
    sid = "UseASGLifecycle"
    actions = [
      "autoscaling:CompleteLifecycleAction"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:autoscaling:${var.region}:${data.aws_caller_identity.k3s.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.prefix}-${local.suffix}-*"]
  }

  statement {
    sid = "cloudprovider"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeAvailabilityZones",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyVolume",
      "ec2:AttachVolume",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteVolume",
      "ec2:DetachVolume",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:DescribeVpcs",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:AttachLoadBalancerToSubnets",
      "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateLoadBalancerPolicy",
      "elasticloadbalancing:CreateLoadBalancerListeners",
      "elasticloadbalancing:ConfigureHealthCheck",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteLoadBalancerListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DetachLoadBalancerFromSubnets",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerPolicies",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
      "iam:CreateServiceLinkedRole",
      "kms:DescribeKey",
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

  statement {
    sid = "efs1"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "ec2:DescribeAvailabilityZones"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "efs2"
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    effect    = "Allow"
    resources = ["*"]


    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid = "efs3"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

}

data "aws_iam_policy_document" "k3s-ec2-nodes" {

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
    sid = "UseASGLifecycle"
    actions = [
      "autoscaling:CompleteLifecycleAction"
    ]
    effect    = "Allow"
    resources = ["arn:${data.aws_partition.k3s.partition}:autoscaling:${var.region}:${data.aws_caller_identity.k3s.account_id}:autoScalingGroup:*:autoScalingGroupName/${local.prefix}-${local.suffix}-*"]
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

  statement {
    sid = "efs1"
    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "ec2:DescribeAvailabilityZones"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "efs2"
    actions = [
      "elasticfilesystem:CreateAccessPoint"
    ]
    effect    = "Allow"
    resources = ["*"]


    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid = "efs3"
    actions = [
      "elasticfilesystem:DeleteAccessPoint"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}

# scaledown
data "aws_iam_policy_document" "k3s-scaledown-trust" {
  statement {
    sid = "ForEc2Only"
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "k3s-scaledown" {

  statement {
    sid = "snskms"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect    = "Allow"
    resources = [aws_kms_key.k3s["sns"].arn]
  }

  statement {
    sid = "listkms"
    actions = [
      "kms:ListKeys"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "usesns"
    actions = [
      "sns:Publish"
    ]
    effect    = "Allow"
    resources = [aws_sns_topic.k3s-scaledown.arn]
  }
}
