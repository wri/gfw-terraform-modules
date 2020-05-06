variable "project" {
  type = string
}

variable "name_suffix" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "load_balancer_arn" {
  type        = string
  default     = ""
  description = "Optional Load Balancer to use for fargate cluster. When left blank, a new LB will be created"
}

variable "load_balancer_security_group" {
  type        = string
  default     = ""
  description = "Optional secuirty group of load balancer with which the task can communicate. Required if load_blancer_arn is not empty"
}

variable "container_name" {
  type        = string
  description = "The name of the container to associate with the load balancer."
}

variable "container_port" {
  type        = number
  description = "The port on the container to associate with the load balancer."
}

variable "listener_port" {
  type        = number
  description = "The port the Load Balancer listern should listen to"
}

variable "desired_count" {
  type        = number
  description = "Number of tasks"
}

variable "fargate_cpu" {
  type = number
}

variable "fargate_memory" {
  type = number
}

variable "auto_scaling_max_cpu_util" {
  type = number
}

variable "auto_scaling_max_capacity" {
  type = number
}

variable "auto_scaling_min_capacity" {
  type = number
}

variable "auto_scaling_cooldown" {
  type = number
}

variable "security_group_ids" {
  type = list(string)
}

variable "task_role_policies" {
  type = list(string)
  default = []
}

variable "task_execution_role_policies" {
  type = list(string)
  default = []
}

variable "container_definition" {
  type        = string
  description = "JSON object defining the task container"
}