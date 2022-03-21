variable "project_prefix" {
  type = string
}

variable "httpOkQuery" {
    type = string
}

variable "httpOkLogGroup" {
    type = string
}

variable "httpErrorsQuery" {
    type = string
}

variable "httpErrorsLogGroup" {
    type = string
}

variable "metricsNamespace" {
  type = string
  default = "HttpErrorRateAlarms"
}

variable "alarm_actions" {
    type = list(string)
    default = []
}

variable "insufficient_data_actions" {
    type = list(string)
    default = [] // No action as it is possible there are simply no HTTP requests coming currently
}

variable "alarm_threshold" {
    description = "The alarm activation threshold, the alarm value is a percantage, so must be 0 - 100"
    type = string
    default = "10"
}

variable "alarm_evaluation_total_points" {
    description = "Number of data points to evaluate before alarming"
    type = string
    default = "2"
}

variable "alarm_evaluation_period" {
    description = "Evaluation period of the data in the alarm in seconds"
    type = string
    default = "120"
}