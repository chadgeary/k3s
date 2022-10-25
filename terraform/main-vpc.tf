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

## Private Network
# private route table(s) per zone
resource "aws_route_table" "k3s-private" {
  for_each = local.private_nets
  vpc_id   = aws_vpc.k3s.id
  dynamic "route" {
    for_each = var.nat_gateways ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.k3s[each.key].id
    }
  }
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
  for_each        = local.subnet-vpce
  subnet_id       = each.value.subnet
  vpc_endpoint_id = each.value.vpce
}

## Public Network
# igw if nat_gateways or lb ports
resource "aws_internet_gateway" "k3s" {
  for_each = var.nat_gateways ? { public = true } : {}
  vpc_id   = aws_vpc.k3s.id
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

# public net(s) per zone
resource "aws_subnet" "k3s-public" {
  for_each          = var.nat_gateways ? local.public_nets : {}
  vpc_id            = aws_vpc.k3s.id
  availability_zone = each.value.zone
  cidr_block        = each.value.cidr
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.value.zone}-public"
  }
}

# public route via internet gateway
resource "aws_route_table" "k3s-public" {
  for_each = var.nat_gateways ? { public = true } : {}
  vpc_id   = aws_vpc.k3s.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k3s["public"].id
  }
  tags = {
    Name = "${local.prefix}-${local.suffix}"
  }
}

# nat gateway
resource "aws_eip" "k3s" {
  for_each = var.nat_gateways ? local.public_nets : {}
  vpc      = true
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.value.zone}"
  }
}

resource "aws_nat_gateway" "k3s" {
  for_each      = var.nat_gateways ? local.public_nets : {}
  allocation_id = aws_eip.k3s[each.key].id
  subnet_id     = aws_subnet.k3s-public[each.key].id
  tags = {
    Name = "${local.prefix}-${local.suffix}-${each.value.zone}"
  }
}
