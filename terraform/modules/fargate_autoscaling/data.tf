

data "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_ids)
  id    = var.public_subnet_ids[count.index]
}

#
# ECS IAM resources
#
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
    ]
  }
}

//data "template_file" "container_definition" {
//  template = file("${path.root}/templates/container_definition.json.tmpl")
//  vars = {
//    image = "${var.repository_url}:latest"
//
//    container_name = var.container_name
//    container_port = var.container_port
//
//    log_group = aws_cloudwatch_log_group.default.name
//
//    secret_name = var.secrets_postgresql-reader_name
//    log_level   = var.log_level
//    project     = var.project
//    environment = var.environment
//    aws_region  = var.region
//  }
//}

data "template_file" "autoscaling_role" {
  template = file("${path.module}/templates/service_role.json.tmpl")
  vars = {
    service = "ecs.application-autoscaling.amazonaws.com"
  }
}

data "local_file" "appautoscaling_role_policy" {

  filename = "${path.module}/templates/appautoscaling_role_policy.json"
}

data "template_file" "ecs_update_service_policy" {
  template = file("${path.module}/templates/iam_policy_update_ecs_service.json.tmpl")
  vars = {
    service_arn = aws_ecs_service.default.id
  }
}