output "bucket_id" {
  value = aws_s3_bucket.default.id
}

output "write_policy_arns" {
  value = aws_iam_policy.s3_write_access[*].arn
}

output "read_policy_arn" {
  value = aws_iam_policy.s3_read_access.arn
}