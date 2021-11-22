variable "project" {
  type = string
}

variable "key_pair" {
  type = string
}

variable "subnets" {
  type = list(string)
}

variable "tags" {
  type = map(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "ecs_role_policy_arns" {
  type = list(string)
}

variable "suffix" {
  type    = string
  default = ""
}

variable "instance_types" {
  type = list(string)
  default = [
    "r5d.4xlarge", "r5d.8xlarge", "r5d.12xlarge", "r5d.16xlarge", "r5d.24xlarge", "c5d.12xlarge", "c5d.18xlarge", "c5d.24xlarge"
  ]
}

variable "use_ephemeral_storage" {
  type    = bool
  default = true
}

variable "ebs_volume_size" {
  type    = number
  default = 30
}

variable "bid_percentage" {
  type    = number
  default = 100
}

variable "max_vcpus" {
  type    = number
  default = 256
}

variable "min_vcpus" {
  type    = number
  default = 0
}

variable "launch_type" {
  type    = string
  default = "SPOT"
}

variable "compute_environment_name" {
  type    = string
  default = "ephemeral_storage"
}