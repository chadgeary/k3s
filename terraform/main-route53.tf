resource "aws_route53_zone" "k3s" {
  name = "${local.prefix}-${local.suffix}.internal"
  vpc {
    vpc_id = aws_vpc.k3s.id
  }
  force_destroy = true
}
