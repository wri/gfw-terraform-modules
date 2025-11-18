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
          regexall("[A-Za-z0-9]", format("PublicRead_%s", each))
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
      sid        = "DenyUnencryptedObjectUploads"
      effect     = "Deny"
      principals = [{
        type        = "*"
        identifiers = ["*"]
      }]
      actions = [
        "s3:PutObject",
      ]
      resources = [
        "${aws_s3_bucket.default.arn}/*",
      ]
      conditions = [{
        test     = "StringNotEquals"
        variable = "s3:x-amz-server-side-encryption"
        values   = ["AES256", "aws:kms"]
      }]
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
# (Mirrors your original "count = ... ? 1 : 0" logic)
resource "aws_s3_bucket_policy" "default" {
  count  = length(local.all_bucket_policy_statements_list) > 0 ? 1 : 0
  bucket = aws_s3_bucket.default.id
  policy = data.aws_iam_policy_document.bucket.json
}

##################################
# IAM policy: WRITE access (per-prefix)
##################################
# Build one aws_iam_policy_document per writeable prefix.
# Using for_each on the data source is supported in 0.13+.
resource "aws_iam_policy" "s3_write_access" {
  for_each = local.write_policy_specs_map

  name = "${var.project}-s3_write_${var.bucket_name}_${each.key}"
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


# Also, TF had trouble deleting one of the old-style policies
# because it was attached to a million roles in dev due to old
# branch leftovers. I'm not sure if the problem will rear its head
# in higher environments. So, create a duplicate of the old policy
# with ignore-changes to avoid breaking anything, and clean up
# later at our leisure.
resource "aws_iam_policy" "s3_write_pipelines_legacy" {
  # IMPORTANT: name must match the real existing policy so TF
  # doesn’t create a new one. For the data-lake dev bucket:
  #   core-s3_write_gfw-data-lake-dev_0
  name = "${var.project}-s3_write_${var.bucket_name}_0"

  # This policy body should match the old one as closely as possible.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",
          "s3:PutBucketLifecycleConfiguration",
        ]
        Resource = "arn:aws:s3:::${var.bucket_name}"
      },
      {
        Effect   = "Allow"
        Action   = "s3:*Object"
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
      },
    ]
  })

  lifecycle {
    # Don't let Terraform try to change or delete this;
    # it exists as a legacy artifact.
    ignore_changes = [policy, tags_all]
  }
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
  name        = "${var.project}-s3_read_${var.bucket_name}"
  description = "Read access to s3://${var.bucket_name}"
  policy      = data.aws_iam_policy_document.read_access.json

  lifecycle {
    ignore_changes = [tags_all]
  }
}
