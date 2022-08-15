locals {
  prefix = var.prefix
  suffix = random_string.suffix.result
}

locals {
  cloudk3s-tags = [
    {
      key                 = "Name"
      value               = "node.${local.prefix}-${local.suffix}.internal"
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = "${local.prefix}-${local.suffix}"
      propagate_at_launch = true
    }
  ]

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
}
