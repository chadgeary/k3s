locals {
  prefix = var.prefix
  suffix = random_string.suffix.result
}

locals {
  cloudk3s-tags-master = [
    {
      key                 = "Name"
      value               = "master.${local.prefix}-${local.suffix}.internal"
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = "${local.prefix}-${local.suffix}-master"
      propagate_at_launch = true
    }
  ]

  cloudk3s-tags-worker = [
    {
      key                 = "Name"
      value               = "worker.${local.prefix}-${local.suffix}.internal"
      propagate_at_launch = true
    },
    {
      key                 = "Cluster"
      value               = "${local.prefix}-${local.suffix}-worker"
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

  vpces = toset(["ec2messages", "kms", "logs", "ssm", "ssmmessages"])

  subnet-vpc = tolist(flatten([for endpoint in aws_vpc_endpoint.cloudk3s-ssm : [for subnet in aws_subnet.cloudk3s-private : "${endpoint.id}+${subnet.id}"]]))

}
