output "ecs_security_group_id" {
  value       = aws_security_group.ecs_tasks.id
  description = "Security group ID of the ECS service security group."
}

output "lb_dns_name" {
  value = length(aws_lb.default) == 1 ? aws_lb.default[0].dns_name : ""
}