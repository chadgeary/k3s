locals {

  prefix = var.prefix
  suffix = coalesce(var.suffix, random_string.suffix.result)
  azs    = slice(data.aws_availability_zones.k3s.names, 0, var.azs)

  private_nets = { for az in local.azs : az =>
    {
      cidr = cidrsubnet(cidrsubnet(var.vpc_cidr, 1, 0), var.azs, index(local.azs, az))
      zone = az
    }
  }

  public_nets = { for az in local.azs : az =>
    {
      cidr = cidrsubnet(cidrsubnet(var.vpc_cidr, 1, 1), var.azs, index(local.azs, az))
      zone = az
    }
  }

  vpces = toset(["ebs", "ec2", "ec2messages", "ecr.api", "ecr.dkr", "elasticfilesystem", "kms", "ssm", "ssmmessages", "sts"])

  subnet-vpce = merge([for subnet in aws_subnet.k3s-private : { for vpce in aws_vpc_endpoint.k3s-vpces : "${subnet.availability_zone}-${strrev(element(split(".", strrev(vpce.service_name)), 0))}" => { "subnet" = subnet.id, "vpce" = vpce.id } }]...)

  # https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html
  aws_addon_uris = {
    af-south-1     = "877085696533.dkr.ecr.af-south-1.amazonaws.com"
    ap-east-1      = "800184023465.dkr.ecr.ap-east-1.amazonaws.com"
    ap-northeast-1 = "602401143452.dkr.ecr.ap-northeast-1.amazonaws.com"
    ap-northeast-2 = "602401143452.dkr.ecr.ap-northeast-2.amazonaws.com"
    ap-northeast-3 = "602401143452.dkr.ecr.ap-northeast-3.amazonaws.com"
    ap-south-1     = "602401143452.dkr.ecr.ap-south-1.amazonaws.com"
    ap-southeast-1 = "602401143452.dkr.ecr.ap-southeast-1.amazonaws.com"
    ap-southeast-2 = "602401143452.dkr.ecr.ap-southeast-2.amazonaws.com"
    ap-southeast-3 = "296578399912.dkr.ecr.ap-southeast-3.amazonaws.com"
    ca-central-1   = "602401143452.dkr.ecr.ca-central-1.amazonaws.com"
    cn-north-1     = "918309763551.dkr.ecr.cn-north-1.amazonaws.com.cn"
    cn-northwest-1 = "961992271922.dkr.ecr.cn-northwest-1.amazonaws.com.cn"
    eu-central-1   = "602401143452.dkr.ecr.eu-central-1.amazonaws.com"
    eu-north-1     = "602401143452.dkr.ecr.eu-north-1.amazonaws.com"
    eu-south-1     = "590381155156.dkr.ecr.eu-south-1.amazonaws.com"
    eu-west-1      = "602401143452.dkr.ecr.eu-west-1.amazonaws.com"
    eu-west-2      = "602401143452.dkr.ecr.eu-west-2.amazonaws.com"
    eu-west-3      = "602401143452.dkr.ecr.eu-west-3.amazonaws.com"
    me-south-1     = "558608220178.dkr.ecr.me-south-1.amazonaws.com"
    sa-east-1      = "602401143452.dkr.ecr.sa-east-1.amazonaws.com"
    us-east-1      = "602401143452.dkr.ecr.us-east-1.amazonaws.com"
    us-east-2      = "602401143452.dkr.ecr.us-east-2.amazonaws.com"
    us-gov-east-1  = "151742754352.dkr.ecr.us-gov-east-1.amazonaws.com"
    us-gov-west-1  = "013241004608.dkr.ecr.us-gov-west-1.amazonaws.com"
    us-west-1      = "602401143452.dkr.ecr.us-west-1.amazonaws.com"
    us-west-2      = "602401143452.dkr.ecr.us-west-2.amazonaws.com"
  }

  # only available in commercial aws, not cn or gov
  ecr_pull_through_caches = data.aws_partition.k3s.partition == "aws" ? {
    quay = "quay.io"
    ecr  = "public.ecr.aws"
  } : {}

  # split cluster_cidr in half, and assign an ip for kubedns
  pod_cidr   = cidrsubnet(var.cluster_cidr, 2, 1)
  svc_cidr   = cidrsubnet(var.cluster_cidr, 2, 2)
  kubedns_ip = cidrhost(local.svc_cidr, 10)

}
