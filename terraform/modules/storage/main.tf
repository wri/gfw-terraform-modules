##################################
# Locals
##################################
locals {
  requester_payer = var.requester_pays == true ? "Requester" : "BucketOwner"
  acl             = var.public == true ? "public" : "private"

  ##########################################################
  # Build bucket policy statements as normalized objects
  # so we can render them deterministically.
  ##########################################################

  # 1. Public read statements
  # Allow anonymous GetObject for specified prefixes
  public_statements_list = [
    for prefix in var.public_folders : {
      sid = substr(
        join(
          "",
          regexall("[A-Za-z0-9]", format("PublicRead_%s", prefix))
        ),
        0,
        64
      )
      effect = "Allow"
      principals = [
        {
          type = "*"
          identifiers = ["*"]
        }
      ]
      actions = [
        "s3:GetObject",
      ]
      resources = [
        "${aws_s3_bucket.default.arn}/${prefix}*",
      ]
      # normalize: always present, even if empty
      conditions = []
    }
  ]

  ########################################
  # Backward-compatibility shim for read_roles
  #
  # The old module expected users to sometimes pass
  #   [
  #     jsonencode(["arn:aws:iam::123:root", "arn:aws:iam::456:root"]),
  #     jsonencode(["arn:aws:iam::789:role/core-emr_profile"])
  #   ]
  # i.e. a list of JSON-encoded arrays of ARNs.
  #
  # The new module just wants a flat list of ARNs:
  #   ["arn:aws:iam::123:root", "arn:aws:iam::456:root", "arn:aws:iam::789:role/core-emr_profile"]
  #
  # We'll accept EITHER form. Here's how:
  ########################################

  # Step 1: best-effort decode each element.
  # - If it's valid JSON that decodes to a list -> use that list.
  # - Otherwise assume it's already a plain ARN string and wrap it as a 1-element list.
  #
  # Terraform doesn't have "try to jsondecode(), fallback", so we do a heuristic:
  # If the string starts with "[" and ends with "]", we assume it's JSON for a list and jsondecode() it.
  # Else we assume it's a raw ARN.
  #
  # NOTE: On Terraform 0.13, you *do* have jsondecode(), and you *do* have regex(), so we can branch on a regex.
  #
  # First coerce every entry in var.read_roles to string, to simplify handling.
  _read_roles_as_strings = [
    for r in var.read_roles : tostring(r)
  ]

  # Split into either a decoded list or a singleton.
  _read_roles_lists = [
    for raw in local._read_roles_as_strings :
    (
      can(regex("^\\[", raw)) && can(regex("\\]$", raw))
      ?
      jsondecode(raw)
      :
      [raw]
    )
  ]

  # Flatten the list-of-lists.
  normalized_read_roles = flatten(local._read_roles_lists)

  # 2. Read-only access for specific IAM roles/ARNs (var.read_roles)
  # Allow GetObject/ListBucket to those principals
  role_statements_list = [
    for role_arn in local.normalized_read_roles : {
      sid = substr(
        join(
          "",
          regexall("[A-Za-z0-9]", format("ReadAccess_%s", role_arn))
        ),
        0,
        64
      )

      effect = "Allow"
      principals = [
        {
          type = "AWS"
          identifiers = [role_arn]
        }
      ]
      actions = [
        "s3:GetObject",
        "s3:ListBucket",
      ]
      resources = [
        aws_s3_bucket.default.arn,
        "${aws_s3_bucket.default.arn}/*",
      ]
      conditions = []
    }
  ]

  # 3. Optional server-side encryption enforcement
  # Deny PutObject if no SSE header is provided
  encryption_statements_list = var.enforce_server_side_encryption ? [
    {
      sid    = "DenyUnencryptedObjectUploads"
      effect = "Deny"
      principals = [
        {
          type = "*"
          identifiers = ["*"]
        }
      ]
      actions = [
        "s3:PutObject",
      ]
      resources = [
        "${aws_s3_bucket.default.arn}/*",
      ]
      conditions = [
        {
          test     = "StringNotEquals"
          variable = "s3:x-amz-server-side-encryption"
          values = ["AES256", "aws:kms"]
        }
      ]
    }
  ] : []

  # Combine all statements into a single list.
  all_bucket_policy_statements_list = concat(
    local.public_statements_list,
    local.role_statements_list,
    local.encryption_statements_list,
  )

  # Turn that list into a map keyed by the statement sid.
  # Terraform 0.13 is happier iterating a map in dynamic blocks.
  all_bucket_policy_statements_map = {
    for st in local.all_bucket_policy_statements_list :
    st.sid => st
  }

  ##########################################################
  # Write access policy specs, one per prefix in write_policy_prefix
  ##########################################################
  write_policy_specs_map = {
    for idx, prefix in var.write_policy_prefix :
    idx => {
      idx    = idx
      prefix = prefix
    }
  }
}

##################################
# S3 Bucket
##################################

resource "aws_s3_bucket" "default" {
  bucket        = var.bucket_name
  acl           = local.acl
  tags          = var.tags
  request_payer = local.requester_payer

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      id      = lifecycle_rule.value["id"]
      enabled = lifecycle_rule.value["enabled"]
      prefix  = lifecycle_rule.value["prefix"]

      dynamic "expiration" {
        for_each = length(keys(lookup(lifecycle_rule.value, "expiration", {}))) == 0 ? [] : [lookup(lifecycle_rule.value, "expiration", {})]
        content {
          date                         = lookup(expiration.value, "date", null)
          days                         = lookup(expiration.value, "days", null)
          expired_object_delete_marker = lookup(expiration.value, "expired_object_delete_marker", null)
        }
      }

      dynamic "transition" {
        for_each = lookup(lifecycle_rule.value, "transition", [])
        content {
          date          = lookup(transition.value, "date", null)
          days          = lookup(transition.value, "days", null)
          storage_class = transition.value.storage_class
        }
      }
    }
  }
}

##################################
# Bucket policy
##################################

# Build a canonical policy document for the bucket using a dynamic statement
# block that iterates our normalized map. This avoids the old template_file
# + aggregator approach and produces stable JSON.
data "aws_iam_policy_document" "bucket" {
  dynamic "statement" {
    for_each = local.all_bucket_policy_statements_map

    content {
      sid    = statement.value.sid
      effect = statement.value.effect

      dynamic "principals" {
        for_each = statement.value.principals
        content {
          type        = principals.value.type
          identifiers = principals.value.identifiers
        }
      }

      actions   = statement.value.actions
      resources = statement.value.resources

      # conditions is always defined (possibly empty list),
      # which keeps Terraform 0.13 happy.
      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

# Attach the bucket policy only if we actually have statements to attach.

# Temporarily disable the new bucket policy attachment until
# we're ready to cut over from the legacy templates.

# resource "aws_s3_bucket_policy" "default" {
#   count  = length(local.all_bucket_policy_statements_list) > 0 ? 1 : 0
#   bucket = aws_s3_bucket.default.id
#   policy = data.aws_iam_policy_document.bucket.json
# }

##################################
# IAM policy: WRITE access (per-prefix)
##################################
# Build one aws_iam_policy_document per writeable prefix.
# Using for_each on the data source is supported in 0.13+.
resource "aws_iam_policy" "s3_write_access" {
  for_each = local.write_policy_specs_map

  name = "${var.project}-s3_write_${var.bucket_name}_${each.key}_v2"
  description = "Write access to s3://${var.bucket_name}/${each.value.prefix}"

  # Build the policy JSON deterministically
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = substr(
          join(
            "",
            regexall("[A-Za-z0-9]", format("WriteAccess_%s", each.value.prefix))
          ),
          0,
          64
        )
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:AbortMultipartUpload",
          "s3:ListBucketMultipartUploads",
          "s3:ListMultipartUploadParts",
        ]
        Resource = [
          "${aws_s3_bucket.default.arn}/${each.value.prefix}*",
        ]
      }
    ]
  })
}


##################################
# IAM policy: READ access (entire bucket)
##################################

# Single read policy that grants GetObject/ListBucket over entire bucket.
data "aws_iam_policy_document" "read_access" {
  statement {
    sid    = "ReadAccessBucket"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.default.arn,
      "${aws_s3_bucket.default.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "s3_read_access" {
  name        = "${var.project}-s3_read_${var.bucket_name}_v2"
  description = "Read access to s3://${var.bucket_name}"
  policy      = data.aws_iam_policy_document.read_access.json

  lifecycle {
    ignore_changes = [tags_all]
  }
}

########################
# Legacy Bucket policies
########################

# Please do not use! Switch to using the new v2 policies above,
# as exposed via SSM

resource "aws_s3_bucket_policy" "legacy" {
  count  = length(var.public_folders) + length(var.read_roles) + (var.enforce_server_side_encryption ? 1 : 0) > 0 ? 1 : 0
  bucket = aws_s3_bucket.default.id
  policy = module.bucket_policy.result_document
}

data "template_file" "public_folders_bucket_policy" {
  count    = length(var.public_folders)
  template = file("${path.module}/templates/bucket_policy_public_read.json.tpl")
  vars = {
    bucket_arn = aws_s3_bucket.default.arn
    prefix     = var.public_folders[count.index]
  }
}

data "template_file" "read_access_role_bucket_policy" {
  count    = length(var.read_roles)
  template = file("${path.module}/templates/bucket_policy_role_read.json.tpl")
  vars = {
    bucket_arn       = aws_s3_bucket.default.arn
    aws_resource_arn = var.read_roles[count.index]
  }
}

data "template_file" "server-side-encryption" {
  count    = var.enforce_server_side_encryption ? 1 : 0
  template = file("${path.module}/templates/bucket_policy_server-side-encryption.json.tpl")
  vars = {
    bucket_arn       = aws_s3_bucket.default.arn
  }
}

# merge pipeline policies into one document
module "bucket_policy" {
  source = "git::https://github.com/cloudposse/terraform-aws-iam-policy-document-aggregator.git?ref=0.6.0"
  source_documents = concat(
    data.template_file.public_folders_bucket_policy[*].rendered,
    data.template_file.read_access_role_bucket_policy[*].rendered,
    data.template_file.server-side-encryption[*].rendered
  )
}

#####################
# Legacy IAM policies
#####################

# Please do not use! Switch to using the new v2 policies above,
# as exposed via SSM

data "template_file" "write_access" {
  count    = length(var.write_policy_prefix)
  template = file("${path.module}/templates/iam_policy_s3_write.json.tpl")
  vars = {
    bucket_arn = aws_s3_bucket.default.arn
    prefix     = var.write_policy_prefix[count.index]
  }
}

resource "aws_iam_policy" "s3_write_legacy" {
  count  = length(var.write_policy_prefix)
  name   = "${var.project}-s3_write_${var.bucket_name}_${count.index}"
  policy = data.template_file.write_access[count.index].rendered
  lifecycle {
    # We only want TF to track existence, not rewrite behavior.
    ignore_changes = [policy, tags_all]
  }
}

data "template_file" "read_access" {
  template = file("${path.module}/templates/iam_policy_s3_read.json.tpl")
  vars = {
    bucket_arn = aws_s3_bucket.default.arn
  }
}

resource "aws_iam_policy" "s3_read_legacy" {
  name   = "${var.project}-s3_read_${var.bucket_name}"
  policy = data.template_file.read_access.rendered
  lifecycle {
    # We only want TF to track existence, not rewrite behavior.
    ignore_changes = [policy, tags_all]
  }
}
