resource "aws_cloudwatch_log_metric_filter" "ok" {
  name           = "${var.project_prefix}-http-ok-responses-count"
  pattern        = var.httpOkQuery
  log_group_name = var.httpOkLogGroup

  metric_transformation {
    name      = "${var.project_prefix}-http-ok-responses-count"
    namespace = var.metricsNamespace
    value     = "1"
    default_value = "0"
    unit = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${var.project_prefix}-http-error-responses-count"
  pattern        = var.httpErrorsQuery
  log_group_name = var.httpErrorsLogGroup

  metric_transformation {
    name      = "${var.project_prefix}-http-error-responses-count"
    namespace = var.metricsNamespace
    value     = "1"
    default_value = "0"
    unit = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "alarm" {
  alarm_name                = "${var.project_prefix}_http_error_rate"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = var.alarm_evaluation_total_points
  threshold                 = var.alarm_threshold
  alarm_description         = "Request error rate has exceeded ${var.alarm_threshold}%"
  alarm_actions = var.alarm_actions
  insufficient_data_actions = var.insufficient_data_actions

  metric_query {
    id          = "e1"
    expression  = "(m2/m1)*100"
    label       = "HTTP Error Rate (%)"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "${var.project_prefix}-http-ok-responses-count"
      namespace   = var.metricsNamespace
      period      = var.alarm_evaluation_period
      stat        = "Sum"
      unit        = "Count"
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "${var.project_prefix}-http-error-responses-count"
      namespace   = var.metricsNamespace
      period      = var.alarm_evaluation_period
      stat        = "Sum"
      unit        = "Count"
    }
  }
}