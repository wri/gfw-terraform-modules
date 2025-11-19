##################################
# Outputs
##################################

output "bucket_id" {
  value = aws_s3_bucket.default.id
}

# write_policy_arns used to rely on count-based splat. With for_each,
# a clean, explicit list comp avoids weird ordering assumptions.
output "write_policy_arns" {
  value = aws_iam_policy.s3_write_legacy[*].arn
}

output "write_policy_arns_v2" {
  value = [for p in aws_iam_policy.s3_write_access : p.arn]
}

output "read_policy_arn" {
  value = aws_iam_policy.s3_read_legacy.arn
}

output "read_policy_arn_v2" {
  value = aws_iam_policy.s3_read_access.arn
}
