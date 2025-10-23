locals {
  base_path = "${var.ssm_prefix}/${var.environment}/${var.namespace}"
  contract_with_meta = merge(
    { contract_version = var.contract_version, env = var.environment, namespace = var.namespace },
    var.contract
  )
}

# JSON contract (optional)
resource "aws_ssm_parameter" "contract_json" {
  count = var.publish_json_contract ? 1 : 0

  name  = "${local.base_path}/contract"
  type  = "String" # identifiers/ARNs only; do not put secrets here
  tier  = "Standard"
  value = jsonencode(local.contract_with_meta)
  tags  = var.tags
}

# Singles (String)
resource "aws_ssm_parameter" "singles" {
  for_each = var.strings

  name  = "${local.base_path}/${each.key}"
  type  = "String"
  tier  = "Standard"
  value = each.value
  tags  = var.tags
}

# Lists (StringList)
resource "aws_ssm_parameter" "lists" {
  for_each = var.lists

  name  = "${local.base_path}/${each.key}"
  type  = "StringList"
  tier  = "Standard"
  value = join(",", each.value) # must be comma-only, no spaces
  tags  = var.tags
}

# SecureString (optional)
resource "aws_ssm_parameter" "secure" {
  for_each = var.secure_strings

  name   = "${local.base_path}/${each.key}"
  type   = "SecureString"
  key_id = length(var.kms_key_id) > 0 ? var.kms_key_id : null
  tier   = "Standard"
  value  = each.value
  tags   = var.tags
}
