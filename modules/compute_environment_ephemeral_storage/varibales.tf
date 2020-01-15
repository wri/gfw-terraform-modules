variable "project" { type = string }
variable "key_pair" { type = string }
variable "subnets" { type = list(string) }
variable "tags" { type = map(string) }
variable "security_group_ids" { type = list(string) }
variable "iam_policy_arn" { type = list(string) }
variable "suffix" { type = string, default = ""}