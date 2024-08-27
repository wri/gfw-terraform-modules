# Load Balancer Security Group
resource "aws_security_group" "lb" {
  name        = substr("${var.project}-ecs-alb${var.name_suffix}", 0, 64)
  description = "Controls access to the ALB"
  vpc_id      = var.vpc_id

  tags = merge(
    { Name = substr("${var.project}-ecs-alb${var.name_suffix}", 0, 64) },
    var.tags
  )
}

# Load Balancer Ingress Rules
resource "aws_security_group_rule" "lb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.lb.id
  protocol          = "tcp"
  from_port         = var.acm_certificate_arn == null ? 80 : var.listener_port
  to_port           = var.acm_certificate_arn == null ? 80 : var.listener_port
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "lb_ingress_https" {
  type              = "ingress"
  count             = var.acm_certificate_arn == null ? 0 : 1
  security_group_id = aws_security_group.lb.id
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
}

# Load Balancer Egress to ECS Tasks
resource "aws_security_group_rule" "lb_to_ecs_egress" {
  type                     = "egress"
  security_group_id        = aws_security_group.lb.id
  protocol                 = "tcp"
  from_port                = var.listener_port
  to_port                  = var.listener_port
  source_security_group_id = aws_security_group.ecs_tasks.id
}

# ECS Tasks Security Group
resource "aws_security_group" "ecs_tasks" {
  name        = substr("${var.project}-ecs-tasks${var.name_suffix}", 0, 64)
  description = "Allow inbound access from the ALB and Batch"
  vpc_id      = var.vpc_id

  tags = merge(
    { Name = substr("${var.project}-ecs-tasks${var.name_suffix}", 0, 64) },
    var.tags
  )
}

# ECS Tasks Ingress Rules
resource "aws_security_group_rule" "ecs_tasks_ingress_from_lb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs_tasks.id
  protocol                 = "tcp"
  from_port                = var.listener_port
  to_port                  = var.listener_port
  source_security_group_id = aws_security_group.lb.id
}

resource "aws_security_group_rule" "ecs_tasks_ingress_from_batch" {
  type                     = "ingress"
  security_group_id        = aws_security_group.ecs_tasks.id
  protocol                 = "tcp"
  from_port                = var.listener_port
  to_port                  = var.listener_port
  source_security_group_id = aws_security_group.batch_instances.id
}

# ECS Tasks Egress Rule
resource "aws_security_group_rule" "ecs_tasks_egress" {
  type              = "egress"
  security_group_id = aws_security_group.ecs_tasks.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
}

# Batch Instances Security Group
resource "aws_security_group" "batch_instances" {
  name        = substr("${var.project}-batch-instances${var.name_suffix}", 0, 64)
  description = "Security group for AWS Batch instances"
  vpc_id      = var.vpc_id

  tags = merge(
    { Name = substr("${var.project}-batch-instances${var.name_suffix}", 0, 64) },
    var.tags
  )
}

# Batch Instances Egress to ECS Tasks
resource "aws_security_group_rule" "batch_to_ecs_egress" {
  type                     = "egress"
  security_group_id        = aws_security_group.batch_instances.id
  protocol                 = "tcp"
  from_port                = var.listener_port
  to_port                  = var.listener_port
  source_security_group_id = aws_security_group.ecs_tasks.id
}