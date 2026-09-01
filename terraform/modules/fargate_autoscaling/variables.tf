variable "project" {
  type = string
}

variable "name_suffix" {
  type    = string
  default = ""
}

variable "cluster_id" {
  type = string
  default = ""
}

variable "cluster_name" {
  type = string
  default = ""
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
  description = "The default port the Load Balancer should listen to. Will be ignored when acm_certificate is set."
  default     = 80
}

variable "desired_count" {
  type        = number
  description = "Number of tasks"
  default     = 1
}

variable "fargate_cpu" {
  type    = number
  default = 1
}

variable "fargate_memory" {
  type    = number
  default = 512
}

variable "auto_scaling_max_cpu_util" {
  type    = number
  default = 75
}

variable "auto_scaling_max_capacity" {
  type    = number
  default = 1
}

variable "auto_scaling_min_capacity" {
  type    = number
  default = 1
}

variable "auto_scaling_cooldown" {
  type    = number
  default = 300
}

variable "security_group_ids" {
  type = list(string)
}

variable "task_role_policies" {
  type    = list(string)
  default = []
}

variable "task_execution_role_policies" {
  type    = list(string)
  default = []
}

variable "container_definition" {
  type        = string
  description = "JSON object defining the task container"
}

variable "force_new_deployment" {
  type    = bool
  default = true
}

variable "acm_certificate_arn" {
  type        = string
  default     = null
  description = "The ACM/ SSL certificate to use. When set, listener port will be set to 443. Request to port 80 will be forwarded. All other ports will be closed."
}

variable "cpu_architecture" {
  type        = string
  description = "CPU architecture for the Fargate task's runtime_platform: \"X86_64\" or \"ARM64\". Defaults to \"X86_64\" to preserve prior behavior for existing callers that don't set this -- that's also what AWS itself defaults to when runtime_platform is omitted, which this module always did before this variable existed. When set to \"ARM64\", the container image(s) in container_definition must also be built for arm64, and Fargate requires platform version 1.4.0 or later (the default LATEST platform version satisfies this)."
  default     = "X86_64"
}

variable "operating_system_family" {
  type        = string
  description = "OS family for the Fargate task's runtime_platform, e.g. \"LINUX\" or a Windows variant like \"WINDOWS_SERVER_2019_FULL\". Defaults to \"LINUX\" to preserve prior behavior for existing callers that don't set this. ARM64 (cpu_architecture) is Linux-only on Fargate -- pairing it with a Windows OS family isn't validated here (this module is pinned to Terraform <0.14, which doesn't support cross-variable validation blocks) but will be rejected by AWS at apply time."
  default     = "LINUX"
}
