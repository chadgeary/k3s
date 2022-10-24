# security group for cluster
resource "aws_security_group" "k3s-ec2" {
  name_prefix = "${local.prefix}-${local.suffix}-ec2"
  description = "SG for ${local.prefix}-${local.suffix} ec2"
  vpc_id      = aws_vpc.k3s.id
  tags = {
    Name = "${local.prefix}-${local.suffix}-ec2"
  }
}

resource "aws_security_group_rule" "k3s-ec2-ingress-self-sg" {
  for_each                 = toset(["443", "6443", "2379", "2380", "10250"])
  type                     = "ingress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s-ec2.id
  source_security_group_id = aws_security_group.k3s-ec2.id
}

resource "aws_security_group_rule" "k3s-ec2-egress-self-sg" {
  for_each                 = toset(["443", "6443", "2379", "2380", "10250"])
  type                     = "egress"
  from_port                = each.value
  to_port                  = each.value
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s-ec2.id
  source_security_group_id = aws_security_group.k3s-ec2.id
}

resource "aws_security_group_rule" "k3s-ec2-ingress-self-lb-private" {
  type              = "ingress"
  from_port         = "6443"
  to_port           = "6443"
  protocol          = "tcp"
  security_group_id = aws_security_group.k3s-ec2.id
  cidr_blocks       = [for net in aws_subnet.k3s-private : net.cidr_block]
}

resource "aws_security_group_rule" "k3s-ec2-egress-self-lb-private" {
  type              = "egress"
  from_port         = "6443"
  to_port           = "6443"
  protocol          = "tcp"
  security_group_id = aws_security_group.k3s-ec2.id
  cidr_blocks       = [for net in aws_subnet.k3s-private : net.cidr_block]
}

resource "aws_security_group_rule" "k3s-ec2-ingress-self-lb-public" {
  for_each          = length(var.public_access.load_balancer_ports) > 0 ? merge(var.public_access.load_balancer_ports, { 10250 = "TCP" }) : {}
  type              = "ingress"
  from_port         = each.key
  to_port           = each.key
  protocol          = lower(each.value)
  security_group_id = aws_security_group.k3s-ec2.id
  cidr_blocks       = [for net in aws_subnet.k3s-public : net.cidr_block]
}

resource "aws_security_group_rule" "k3s-ec2-egress-s3" {
  type              = "egress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  security_group_id = aws_security_group.k3s-ec2.id
  prefix_list_ids   = [aws_vpc_endpoint.k3s-s3.prefix_list_id]
}

resource "aws_security_group_rule" "k3s-ec2-egress-endpoints" {
  type                     = "egress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s-ec2.id
  source_security_group_id = aws_security_group.k3s-endpoints.id
}

resource "aws_security_group_rule" "k3s-ec2-egress-rds" {
  type                     = "egress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s-ec2.id
  source_security_group_id = aws_security_group.k3s-rds.id
}

# security group for endpoints
resource "aws_security_group" "k3s-endpoints" {
  name_prefix = "${local.prefix}-${local.suffix}-endpoints"
  description = "SG for ${local.prefix}-${local.suffix}-endpoints"
  vpc_id      = aws_vpc.k3s.id
  tags = {
    Name = "${local.prefix}-${local.suffix}-endpoints"
  }
}

resource "aws_security_group_rule" "k3s-endpoints-ingress-ec2-sg" {
  type                     = "ingress"
  from_port                = "443"
  to_port                  = "443"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s-endpoints.id
  source_security_group_id = aws_security_group.k3s-ec2.id
}

resource "aws_security_group_rule" "k3s-endpoints-ingress-ec2-net" {
  type              = "ingress"
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  security_group_id = aws_security_group.k3s-endpoints.id
  cidr_blocks       = [for net in aws_subnet.k3s-private : net.cidr_block]
}

# security group for rds db
resource "aws_security_group" "k3s-rds" {
  name_prefix = "${local.prefix}-${local.suffix}-rds"
  description = "SG for ${local.prefix}-${local.suffix}-rds"
  vpc_id      = aws_vpc.k3s.id
  tags = {
    Name = "${local.prefix}-${local.suffix}-rds"
  }
}

resource "aws_security_group_rule" "k3s-rds-ingress-ec2-sg" {
  type                     = "ingress"
  from_port                = "5432"
  to_port                  = "5432"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s-rds.id
  source_security_group_id = aws_security_group.k3s-ec2.id
}
