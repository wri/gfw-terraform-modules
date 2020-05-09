
#
# NLB Resources
#
resource "aws_lb" "default" {
  count                            = var.load_balancer_arn == "" ? 1 : 0
  name                             = substr("${var.project}-elb${var.name_suffix}", 0, 32)
  enable_cross_zone_load_balancing = true

  subnets         = var.public_subnet_ids
  security_groups = [aws_security_group.lb[0].id]

  tags = merge(
    {
      Job = var.project,
    },
    var.tags
  )
}

resource "aws_lb_target_group" "default" {
  name = substr("${var.project}-tg${var.name_suffix}", 0, 32)
  //
  //  health_check {
  //    protocol          = "TCP"
  //    interval          = "30"
  //    healthy_threshold = "3"
  //    # For Network Load Balancers, this value must be the same as the healthy_threshold.
  //    unhealthy_threshold = "3"
  //  }

  port     = var.container_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  target_type = "ip"

  tags = merge(
    {
      Job = var.project,
    },
    var.tags
  )
}

resource "aws_lb_listener" "default" {
  load_balancer_arn = length(aws_lb.default) == 1 ? aws_lb.default[0].arn : var.load_balancer_arn
  port              = var.listener_port
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.default.id
    type             = "forward"
  }
}