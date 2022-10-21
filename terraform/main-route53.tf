resource "aws_route53_zone" "k3s" {
  name = "${local.prefix}-${local.suffix}.internal"
  vpc {
    vpc_id = aws_vpc.k3s.id
  }
  force_destroy = true
}

resource "aws_route53_record" "k3s-private" {
  zone_id = aws_route53_zone.k3s.zone_id
  name    = "${local.prefix}-${local.suffix}.internal"
  type    = "A"
  alias {
    name                   = aws_lb.k3s-private.dns_name
    zone_id                = aws_lb.k3s-private.zone_id
    evaluate_target_health = true
  }
}
