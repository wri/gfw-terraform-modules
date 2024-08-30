# ALB Security Group
# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "lb" {
  count       = var.load_balancer_security_group == "" ? 1 : 0
  name        = substr("${var.project}-ecs-alb${var.name_suffix}", 0, 64)
  description = "Controls access to the ALB"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = substr("${var.project}-ecs-alb${var.name_suffix}", 0, 64)
    },
    var.tags
  )
}

# Externally defined ingress rules for ALB Security Group
resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = var.load_balancer_security_group == "" ? aws_security_group.lb[0].id : var.load_balancer_security_group
  protocol          = "tcp"
  from_port         = var.acm_certificate_arn == null ? 80 : var.listener_port
  to_port           = var.acm_certificate_arn == null ? 80 : var.listener_port
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  count             = var.acm_certificate_arn == null ? 0 : 1
  security_group_id = aws_security_group.lb[0].id
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "ingress"
}

# ECS Tasks Security Group
resource "aws_security_group" "ecs_tasks" {
  name        = substr("${var.project}-ecs-tasks${var.name_suffix}", 0, 64)
  description = "Allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = substr("${var.project}-ecs-tasks${var.name_suffix}", 0, 64)
    },
    var.tags
  )
}

# Externally defined ingress rule for ECS Tasks Security Group
resource "aws_security_group_rule" "ecs_tasks_ingress" {
  security_group_id         = aws_security_group.ecs_tasks.id
  protocol                  = "tcp"
  from_port                 = var.container_port
  to_port                   = var.container_port
  source_security_group_id  = var.load_balancer_security_group == "" ? aws_security_group.lb[0].id : var.load_balancer_security_group
  type                      = "ingress"
}

# Externally defined egress rule for ECS Tasks Security Group
resource "aws_security_group_rule" "ecs_tasks_egress" {
  security_group_id = aws_security_group.ecs_tasks.id
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  type              = "egress"
}

# Egress rule for Load Balancer to ECS Tasks
resource "aws_security_group_rule" "lb_task_egress" {
  security_group_id        = var.load_balancer_security_group == "" ? aws_security_group.lb[0].id : var.load_balancer_security_group
  from_port                = var.container_port
  to_port                  = var.container_port
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = aws_security_group.ecs_tasks.id
}

# Security group for Batch jobs
resource "aws_security_group" "batch_instances" {
  name        = substr("${var.project}-batch-instances${var.name_suffix}", 0, 64)
  description = "Security group for AWS Batch jobs"
  vpc_id      = var.vpc_id

  tags = merge(
    {
      Name = substr("${var.project}-batch-instances${var.name_suffix}", 0, 64)
    },
    var.tags
  )
}

resource "aws_security_group_rule" "ecs_tasks_egress_batch" {
  security_group_id = aws_security_group.ecs_tasks.id
  protocol          = "tcp"
  from_port         = var.listener_port
  to_port           = var.listener_port
  source_security_group_id = aws_security_group.batch_instances.id
  type              = "egress"
}