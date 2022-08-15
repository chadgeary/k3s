resource "aws_route53_zone" "cloudk3s" {
  name = "${local.prefix}-${local.suffix}.internal"
  vpc {
    vpc_id = aws_vpc.cloudk3s.id
  }
  force_destroy = true
}

resource "aws_route53_record" "cloudk3s-private" {
  zone_id = aws_route53_zone.cloudk3s.zone_id
  name    = "${local.prefix}-${local.suffix}.internal"
  type    = "A"
  alias {
    name                   = aws_lb.cloudk3s-private.dns_name
    zone_id                = aws_lb.cloudk3s-private.zone_id
    evaluate_target_health = true
  }
}
