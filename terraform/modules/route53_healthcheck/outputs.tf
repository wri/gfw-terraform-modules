output "sns_topic_arn" {
    value = aws_sns_topic.healthcheck_updates.arn
}