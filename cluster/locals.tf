locals {
  prefix = var.prefix
  suffix = random_string.suffix.result
}

locals {

  azs = slice(data.aws_availability_zones.cloudk3s.names, 0, var.azs)

  private_nets = { for az in local.azs : az =>
    {
      cidr = cidrsubnet(var.vpc_cidr, 4, index(local.azs, az))
      zone = az
    }
  }

  public_nets = { for az in local.azs : az =>
    {
      cidr = cidrsubnet(var.vpc_cidr, 4, index(local.azs, az) + 8)
      zone = az
    }
  }

  vpces = toset(["ec2messages", "kms", "logs", "ssm", "ssmmessages"])

  subnet-vpc = tolist(flatten([for endpoint in aws_vpc_endpoint.cloudk3s-vpces : [for subnet in aws_subnet.cloudk3s-private : "${endpoint.id}+${subnet.id}"]]))

}
