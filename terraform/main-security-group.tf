# security group for cluster
resource "aws_security_group" "k3s-ec2" {
  name_prefix = "${local.prefix}-${local.suffix}-ec2"
  description = "SG for ${local.prefix}-${local.suffix} ec2"
  vpc_id      = aws_vpc.k3s.id
  tags = {
    Name                                                    = "${local.prefix}-${local.suffix}-ec2"
    "kubernetes.io/cluster/${local.prefix}-${local.suffix}" = "shared"
  }
}

resource "aws_security_group_rule" "k3s-ec2-ingress-self-sg" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  security_group_id        = aws_security_group.k3s-ec2.id
  source_security_group_id = aws_security_group.k3s-ec2.id
}

resource "aws_security_group_rule" "k3s-ec2-egress-self-sg" {
  type                     = "egress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
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

resource "aws_security_group_rule" "k3s-ec2-egress-world" {
  for_each          = var.nat_gateways ? { public = "true" } : {}
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "all"
  security_group_id = aws_security_group.k3s-ec2.id
  cidr_blocks       = ["0.0.0.0/0"]
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

resource "aws_security_group_rule" "k3s-ec2-egress-efs" {
  type                     = "egress"
  from_port                = "2049"
  to_port                  = "2049"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s-ec2.id
  source_security_group_id = aws_security_group.k3s-efs.id
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

# security group for efs
resource "aws_security_group" "k3s-efs" {
  name_prefix = "${local.prefix}-${local.suffix}-efs"
  description = "SG for ${local.prefix}-${local.suffix}-efs"
  vpc_id      = aws_vpc.k3s.id
  tags = {
    Name = "${local.prefix}-${local.suffix}-efs"
  }
}

resource "aws_security_group_rule" "k3s-efs-ingress-ec2-sg" {
  type                     = "ingress"
  from_port                = "2049"
  to_port                  = "2049"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.k3s-efs.id
  source_security_group_id = aws_security_group.k3s-ec2.id
}
