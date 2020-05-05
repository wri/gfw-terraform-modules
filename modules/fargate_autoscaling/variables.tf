//variable "environment" {
//  type        = string
//  description = "An environment namespace for the infrastructure."
//}
//
//variable "region" {
//  type = string
//}
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


//variable "repository_url" {
//  type = string
//}
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

//variable "deployment_min_percent" {
//  type = number
//}
//
//variable "deployment_max_percent" {
//  type = number
//}

variable "fargate_cpu" {
  type = number
}

variable "fargate_memory" {
  type = number
}

//variable "log_level" {
//  type = string
//}

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

variable "task_role_policy_arn" {
  type = string
}

//variable "secrets_postgresql-reader_name" {
//  type = string
//}
//
//variable "log_retention" {
//  type = number
//  default = 30
//  description = "Retention time of task logs in days"
//}


variable "container_definition" {
  type        = map(string)
  description = "JSON object defining the task container"
}