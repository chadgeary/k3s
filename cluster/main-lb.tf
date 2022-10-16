resource "aws_lb" "cloudk3s-private" {
  name                             = "${local.prefix}-${local.suffix}-private"
  load_balancer_type               = "network"
  internal                         = true
  enable_cross_zone_load_balancing = true
  subnets                          = [ for key, value in aws_subnet.cloudk3s-private : value.id ]

  tags = {
    Name = "${local.prefix}-${local.suffix}-private"
  }
}

resource "aws_lb_listener" "cloudk3s-private" {
  port              = "6443"
  protocol          = "TCP"
  load_balancer_arn = aws_lb.cloudk3s-private.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cloudk3s-private.arn
  }
  tags = {
    Name = "${local.prefix}-${local.suffix}-private"
  }
}

resource "aws_lb_target_group" "cloudk3s-private" {
  port                 = "6443"
  name                 = "${local.prefix}-${local.suffix}-private"
  protocol             = "TCP"
  vpc_id               = aws_vpc.cloudk3s.id
  preserve_client_ip   = true
  deregistration_delay = 10
  stickiness {
    enabled = true
    type    = "source_ip"
  }
  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 10
    protocol            = "TCP"
  }
  tags = {
    Name = "${local.prefix}-${local.suffix}-private"
  }
}
