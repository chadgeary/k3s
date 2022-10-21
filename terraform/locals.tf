locals {
  prefix = var.prefix
  suffix = coalesce(var.suffix, random_string.suffix.result)
}

locals {

  azs = slice(data.aws_availability_zones.k3s.names, 0, var.azs)

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

  vpces = toset(["ec2messages", "kms", "logs", "ssm", "ssmmessages"])

  subnet-vpc = tolist(flatten([for endpoint in aws_vpc_endpoint.k3s-vpces : [for subnet in aws_subnet.k3s-private : "${endpoint.id}+${subnet.id}"]]))

}
