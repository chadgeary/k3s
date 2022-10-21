# vpc
resource "aws_vpc" "k3s" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

# route53 
resource "aws_vpc_dhcp_options" "k3s" {
  domain_name         = "${local.prefix}-${local.suffix}.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
}

resource "aws_vpc_dhcp_options_association" "k3s" {
  vpc_id          = aws_vpc.k3s.id
  dhcp_options_id = aws_vpc_dhcp_options.k3s.id
}

# private route table(s) per zone
resource "aws_route_table" "k3s-private" {
  for_each = local.public_nets
  vpc_id   = aws_vpc.k3s.id
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.value.zone}"
  }
}

# private subnets
resource "aws_subnet" "k3s-private" {
  for_each          = local.private_nets
  vpc_id            = aws_vpc.k3s.id
  availability_zone = each.value.zone
  cidr_block        = each.value.cidr
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.value.zone}-private"
  }
}

# private route table associations
resource "aws_route_table_association" "k3s-private" {
  for_each       = local.private_nets
  subnet_id      = aws_subnet.k3s-private[each.key].id
  route_table_id = aws_route_table.k3s-private[each.key].id
}

# s3 endpoint for private instance(s)
resource "aws_vpc_endpoint" "k3s-s3" {
  vpc_id            = aws_vpc.k3s.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for aws_route_table in aws_route_table.k3s-private : aws_route_table.id]
  tags = {
    Name = "${local.prefix}-${local.suffix}-s3"
  }
}

# ssm endpoints for private instance(s)
resource "aws_vpc_endpoint" "k3s-vpces" {
  for_each            = local.vpces
  vpc_id              = aws_vpc.k3s.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.k3s-endpoints.id]
  private_dns_enabled = true
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.key}"
  }
}

resource "aws_vpc_endpoint_subnet_association" "k3s-vpces" {
  # variable azs requires setting the number of resources this creates on hard values
  count = length(local.vpces) * var.azs

  subnet_id       = element(split("+", local.subnet-vpc[count.index]), 1)
  vpc_endpoint_id = element(split("+", local.subnet-vpc[count.index]), 0)

}
