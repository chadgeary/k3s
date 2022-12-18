## autoscaling
resource "aws_iam_service_linked_role" "k3s" {
  aws_service_name = "autoscaling.amazonaws.com"
  custom_suffix    = "${local.prefix}-${local.suffix}"
}

resource "aws_iam_policy" "k3s-ec2-passrole" {
  name   = "${local.prefix}-${local.suffix}-ec2-passrole"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-ec2-passrole.json
}

resource "aws_iam_user_policy_attachment" "k3s-ec2-passrole" {
  user       = element(split("/", data.aws_caller_identity.k3s.arn), 1)
  policy_arn = aws_iam_policy.k3s-ec2-passrole.arn
}

## codebuild
resource "aws_iam_role" "k3s-codebuild" {
  name               = "${local.prefix}-${local.suffix}-codebuild"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-codebuild-trust.json
}

resource "aws_iam_policy" "k3s-codebuild" {
  name   = "${local.prefix}-${local.suffix}-codebuild"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-codebuild.json
}

resource "aws_iam_role_policy_attachment" "k3s-codebuild" {
  role       = aws_iam_role.k3s-codebuild.name
  policy_arn = aws_iam_policy.k3s-codebuild.arn
}

## codepipeline
resource "aws_iam_role" "k3s-codepipeline" {
  name               = "${local.prefix}-${local.suffix}-codepipeline"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-codepipeline-trust.json
}

resource "aws_iam_policy" "k3s-codepipeline" {
  name   = "${local.prefix}-${local.suffix}-codepipeline"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-codepipeline.json
}

resource "aws_iam_role_policy_attachment" "k3s-codepipeline" {
  role       = aws_iam_role.k3s-codepipeline.name
  policy_arn = aws_iam_policy.k3s-codepipeline.arn
}

## ec2 
resource "aws_iam_role" "k3s-ec2-controlplane" {
  name               = "${local.prefix}-${local.suffix}-ec2-controlplane"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-ec2-trust.json
}

resource "aws_iam_policy" "k3s-ec2-controlplane" {
  name   = "${local.prefix}-${local.suffix}-ec2-controlplane"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-ec2-controlplane.json
}

resource "aws_iam_role_policy_attachment" "k3s-ec2-controlplane" {
  role       = aws_iam_role.k3s-ec2-controlplane.name
  policy_arn = aws_iam_policy.k3s-ec2-controlplane.arn
}

resource "aws_iam_role_policy_attachment" "k3s-ec2-controlplane-managed" {
  role       = aws_iam_role.k3s-ec2-controlplane.name
  policy_arn = data.aws_iam_policy.k3s-ec2-managed.arn
}

resource "aws_iam_instance_profile" "k3s-ec2-controlplane" {
  name = "${local.prefix}-${local.suffix}-ec2-controlplane"
  role = aws_iam_role.k3s-ec2-controlplane.name
}

resource "aws_iam_role" "k3s-ec2-nodes" {
  name               = "${local.prefix}-${local.suffix}-ec2-nodes"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-ec2-trust.json
}

resource "aws_iam_policy" "k3s-ec2-nodes" {
  name   = "${local.prefix}-${local.suffix}-ec2-nodes"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-ec2-nodes.json
}

resource "aws_iam_role_policy_attachment" "k3s-ec2-nodes" {
  role       = aws_iam_role.k3s-ec2-nodes.name
  policy_arn = aws_iam_policy.k3s-ec2-nodes.arn
}

resource "aws_iam_role_policy_attachment" "k3s-ec2-nodes-managed" {
  role       = aws_iam_role.k3s-ec2-nodes.name
  policy_arn = data.aws_iam_policy.k3s-ec2-managed.arn
}

resource "aws_iam_instance_profile" "k3s-ec2-nodes" {
  name = "${local.prefix}-${local.suffix}-ec2-nodes"
  role = aws_iam_role.k3s-ec2-nodes.name
}

## lambda
resource "aws_iam_role" "k3s-lambda-getk3s" {
  name               = "${local.prefix}-${local.suffix}-lambda-getk3s"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-lambda-getk3s-trust.json
}

resource "aws_iam_policy" "k3s-lambda-getk3s" {
  name   = "${local.prefix}-${local.suffix}-lambda-getk3s"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-lambda-getk3s.json
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-getk3s" {
  role       = aws_iam_role.k3s-lambda-getk3s.name
  policy_arn = aws_iam_policy.k3s-lambda-getk3s.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-getk3s-managed-1" {
  role       = aws_iam_role.k3s-lambda-getk3s.name
  policy_arn = data.aws_iam_policy.k3s-lambda-getk3s-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-getk3s-managed-2" {
  role       = aws_iam_role.k3s-lambda-getk3s.name
  policy_arn = data.aws_iam_policy.k3s-lambda-getk3s-managed-2.arn
}

resource "aws_iam_role" "k3s-lambda-oidcprovider" {
  name               = "${local.prefix}-${local.suffix}-lambda-oidcprovider"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-lambda-oidcprovider-trust.json
}

resource "aws_iam_policy" "k3s-lambda-oidcprovider" {
  name   = "${local.prefix}-${local.suffix}-lambda-oidcprovider"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-lambda-oidcprovider.json
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-oidcprovider" {
  role       = aws_iam_role.k3s-lambda-oidcprovider.name
  policy_arn = aws_iam_policy.k3s-lambda-oidcprovider.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-oidcprovider-managed-1" {
  role       = aws_iam_role.k3s-lambda-oidcprovider.name
  policy_arn = data.aws_iam_policy.k3s-lambda-oidcprovider-managed-1.arn
}

resource "aws_iam_role_policy_attachment" "k3s-lambda-oidcprovider-managed-2" {
  role       = aws_iam_role.k3s-lambda-oidcprovider.name
  policy_arn = data.aws_iam_policy.k3s-lambda-oidcprovider-managed-2.arn
}

## irsa
resource "aws_iam_role" "k3s-irsa" {
  name               = "${local.prefix}-${local.suffix}-irsa"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-irsa-trust.json
  depends_on         = [data.aws_lambda_invocation.k3s-oidcprovider]
}

resource "aws_iam_policy" "k3s-irsa" {
  name   = "${local.prefix}-${local.suffix}-irsa"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-irsa.json
}

resource "aws_iam_role_policy_attachment" "k3s-irsa" {
  role       = aws_iam_role.k3s-irsa.name
  policy_arn = aws_iam_policy.k3s-irsa.arn
}

## aws-cloud-controller-manager
resource "aws_iam_role" "k3s-aws-cloud-controller-manager" {
  name               = "${local.prefix}-${local.suffix}-aws-cloud-controller-manager"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-aws-cloud-controller-manager-trust.json
  depends_on         = [data.aws_lambda_invocation.k3s-oidcprovider]
}

resource "aws_iam_policy" "k3s-aws-cloud-controller-manager" {
  name   = "${local.prefix}-${local.suffix}-aws-cloud-controller-manager"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-aws-cloud-controller-manager.json
}

resource "aws_iam_role_policy_attachment" "k3s-aws-cloud-controller-manager" {
  role       = aws_iam_role.k3s-aws-cloud-controller-manager.name
  policy_arn = aws_iam_policy.k3s-aws-cloud-controller-manager.arn
}

## aws-vpc-cni
resource "aws_iam_role" "k3s-aws-vpc-cni" {
  name               = "${local.prefix}-${local.suffix}-aws-vpc-cni"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-aws-vpc-cni-trust.json
  depends_on         = [data.aws_lambda_invocation.k3s-oidcprovider]
}

resource "aws_iam_policy" "k3s-aws-vpc-cni" {
  name   = "${local.prefix}-${local.suffix}-aws-vpc-cni"
  path   = "/"
  policy = data.aws_iam_policy_document.k3s-aws-vpc-cni.json
}

resource "aws_iam_role_policy_attachment" "k3s-aws-vpc-cni" {
  role       = aws_iam_role.k3s-aws-vpc-cni.name
  policy_arn = aws_iam_policy.k3s-aws-vpc-cni.arn
}

## external-dns - only viable if using nat gateway(s)
resource "aws_iam_role" "k3s-external-dns" {
  for_each           = var.nat_gateways ? { external-dns = true } : {}
  name               = "${local.prefix}-${local.suffix}-external-dns"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-external-dns-trust["external-dns"].json
  depends_on         = [data.aws_lambda_invocation.k3s-oidcprovider]
}

resource "aws_iam_policy" "k3s-external-dns" {
  for_each = var.nat_gateways ? { external-dns = true } : {}
  name     = "${local.prefix}-${local.suffix}-external-dns"
  path     = "/"
  policy   = data.aws_iam_policy_document.k3s-external-dns["external-dns"].json
}

resource "aws_iam_role_policy_attachment" "k3s-external-dns" {
  for_each   = var.nat_gateways ? { external-dns = true } : {}
  role       = aws_iam_role.k3s-external-dns["external-dns"].name
  policy_arn = aws_iam_policy.k3s-external-dns["external-dns"].arn
}

## aws-lb-controller
resource "aws_iam_role" "k3s-aws-lb-controller" {
  name               = "${local.prefix}-${local.suffix}-aws-lb-controller"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.k3s-aws-lb-controller-trust.json
  depends_on         = [data.aws_lambda_invocation.k3s-oidcprovider]
}

resource "aws_iam_policy" "k3s-aws-lb-controller" {
  name = "${local.prefix}-${local.suffix}-aws-lb-controller"
  path = "/"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "iam:CreateServiceLinkedRole"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "iam:AWSServiceName" : "elasticloadbalancing.amazonaws.com"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:DescribeAccountAttributes",
            "ec2:DescribeAddresses",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeInternetGateways",
            "ec2:DescribeVpcs",
            "ec2:DescribeVpcPeeringConnections",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeInstances",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DescribeTags",
            "ec2:GetCoipPoolUsage",
            "ec2:DescribeCoipPools",
            "elasticloadbalancing:DescribeLoadBalancers",
            "elasticloadbalancing:DescribeLoadBalancerAttributes",
            "elasticloadbalancing:DescribeListeners",
            "elasticloadbalancing:DescribeListenerCertificates",
            "elasticloadbalancing:DescribeSSLPolicies",
            "elasticloadbalancing:DescribeRules",
            "elasticloadbalancing:DescribeTargetGroups",
            "elasticloadbalancing:DescribeTargetGroupAttributes",
            "elasticloadbalancing:DescribeTargetHealth",
            "elasticloadbalancing:DescribeTags"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "cognito-idp:DescribeUserPoolClient",
            "acm:ListCertificates",
            "acm:DescribeCertificate",
            "iam:ListServerCertificates",
            "iam:GetServerCertificate",
            "waf-regional:GetWebACL",
            "waf-regional:GetWebACLForResource",
            "waf-regional:AssociateWebACL",
            "waf-regional:DisassociateWebACL",
            "wafv2:GetWebACL",
            "wafv2:GetWebACLForResource",
            "wafv2:AssociateWebACL",
            "wafv2:DisassociateWebACL",
            "shield:GetSubscriptionState",
            "shield:DescribeProtection",
            "shield:CreateProtection",
            "shield:DeleteProtection"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateSecurityGroup"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags"
          ],
          "Resource" : "arn:${data.aws_partition.k3s.partition}:ec2:${var.region}:${data.aws_caller_identity.k3s.account_id}:security-group/*",
          "Condition" : {
            "StringEquals" : {
              "ec2:CreateAction" : "CreateSecurityGroup"
            },
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:CreateTags",
            "ec2:DeleteTags"
          ],
          "Resource" : "arn:${data.aws_partition.k3s.partition}:ec2:${var.region}:${data.aws_caller_identity.k3s.account_id}:security-group/*",
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:DeleteSecurityGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:CreateLoadBalancer",
            "elasticloadbalancing:CreateTargetGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:CreateListener",
            "elasticloadbalancing:DeleteListener",
            "elasticloadbalancing:CreateRule",
            "elasticloadbalancing:DeleteRule"
          ],
          "Resource" : "*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
          ],
          "Resource" : [
            "arn:${data.aws_partition.k3s.partition}:elasticloadbalancing:${var.region}:${data.aws_caller_identity.k3s.account_id}:targetgroup/*/*",
            "arn:${data.aws_partition.k3s.partition}:elasticloadbalancing:${var.region}:${data.aws_caller_identity.k3s.account_id}:loadbalancer/net/*/*",
            "arn:${data.aws_partition.k3s.partition}:elasticloadbalancing:${var.region}:${data.aws_caller_identity.k3s.account_id}:loadbalancer/app/*/*"
          ],
          "Condition" : {
            "Null" : {
              "aws:RequestTag/elbv2.k8s.aws/cluster" : "true",
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:AddTags",
            "elasticloadbalancing:RemoveTags"
          ],
          "Resource" : [
            "arn:${data.aws_partition.k3s.partition}:elasticloadbalancing:${var.region}:${data.aws_caller_identity.k3s.account_id}:listener/net/*/*/*",
            "arn:${data.aws_partition.k3s.partition}:elasticloadbalancing:${var.region}:${data.aws_caller_identity.k3s.account_id}:listener/app/*/*/*",
            "arn:${data.aws_partition.k3s.partition}:elasticloadbalancing:${var.region}:${data.aws_caller_identity.k3s.account_id}:listener-rule/net/*/*/*",
            "arn:${data.aws_partition.k3s.partition}:elasticloadbalancing:${var.region}:${data.aws_caller_identity.k3s.account_id}:listener-rule/app/*/*/*"
          ]
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:ModifyLoadBalancerAttributes",
            "elasticloadbalancing:SetIpAddressType",
            "elasticloadbalancing:SetSecurityGroups",
            "elasticloadbalancing:SetSubnets",
            "elasticloadbalancing:DeleteLoadBalancer",
            "elasticloadbalancing:ModifyTargetGroup",
            "elasticloadbalancing:ModifyTargetGroupAttributes",
            "elasticloadbalancing:DeleteTargetGroup"
          ],
          "Resource" : "*",
          "Condition" : {
            "Null" : {
              "aws:ResourceTag/elbv2.k8s.aws/cluster" : "false"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:RegisterTargets",
            "elasticloadbalancing:DeregisterTargets"
          ],
          "Resource" : "arn:${data.aws_partition.k3s.partition}:elasticloadbalancing:${var.region}:${data.aws_caller_identity.k3s.account_id}:targetgroup/*/*"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "elasticloadbalancing:SetWebAcl",
            "elasticloadbalancing:ModifyListener",
            "elasticloadbalancing:AddListenerCertificates",
            "elasticloadbalancing:RemoveListenerCertificates",
            "elasticloadbalancing:ModifyRule"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "k3s-aws-lb-controller" {
  role       = aws_iam_role.k3s-aws-lb-controller.name
  policy_arn = aws_iam_policy.k3s-aws-lb-controller.arn
}
