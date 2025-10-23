variable "environment" {
  description = "Environment short name (e.g. dev|staging|production)"
  type        = string
}

variable "ssm_prefix" {
  description = "Base SSM path. Final path = <ssm_prefix>/<env>/<namespace>/..."
  type        = string
  default     = "/infra"
}

variable "namespace" {
  description = "Logical name for this contract (e.g., gfw-core or gfw-aws-core-infra)"
  type        = string
}

variable "contract_version" {
  description = "Semver for this contract. Bump on breaking changes."
  type        = string
  default     = "1.0.0"
}

# Everything you want to publish as a single JSON blob.
# You can nest maps/lists/strings/numbers; it will be jsonencoded.
variable "contract" {
  description = "Arbitrary JSON-serializable map of identifiers to publish as one JSON parameter"
  type        = any
  default     = {}
}

# Convenience singles as String (non-secret identifiers/ARNs)
variable "strings" {
  description = "Map of name => string for individual String parameters"
  type        = map(string)
  default     = {}
}

# Convenience lists as StringList (comma-separated)
variable "lists" {
  description = "Map of name => list(string) for individual StringList parameters"
  type        = map(list(string))
  default     = {}
}

# Secure strings (e.g., read-only creds if you insist on SSM; Secrets Manager is still preferred)
variable "secure_strings" {
  description = "Map of name => string for individual SecureString parameters"
  type        = map(string)
  default     = {}
}

variable "kms_key_id" {
  description = "Optional KMS key id/arn to encrypt SecureString parameters"
  type        = string
  default     = ""
}

variable "publish_json_contract" {
  description = "Whether to publish the JSON contract parameter"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all SSM parameters"
  type        = map(string)
  default     = {}
}