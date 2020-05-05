# ALB Security group
# This is the group you need to edit if you want to restrict access to your application
resource "aws_security_group" "lb" {
  count       = var.load_balancer_arn == "" ? 1 : 0
  name        = "${var.project}-ecs-alb${var.name_suffix}"
  description = "Controls access to the ALB"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.listener_port
    to_port     = var.listener_port
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.project}-ecs-alb${var.name_suffix}"
    },
    var.tags
  )
}

# these rules depends on other security groups so separating them allows them
# to be created after both
resource "aws_security_group_rule" "lb_task_egress" {
  count                    = var.load_balancer_arn == "" ? 1 : 0
  security_group_id        = aws_security_group.lb[0].id
  from_port                = var.listener_port
  to_port                  = var.listener_port
  protocol                 = "tcp"
  type                     = "egress"
  source_security_group_id = aws_security_group.ecs_tasks.id
}

# Traffic to the ECS Cluster should only come from the ALB
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project}-ecs-tasks${var.name_suffix}"
  description = "Allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = var.load_balancer_arn == "" ? [aws_security_group.lb[0].id] : [var.load_balancer_security_group]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.project}-ecs-tasks${var.name_suffix}"
    },
    var.tags
  )
}
