terraform {
  required_version = ">=0.12.13"
}

locals {
  tags = merge(
      {
        Name = "${var.project}-ephemeral-storage-batch-job${var.suffix}",
        Job  = "Batch Job"
      },

    var.tags)
}

resource "aws_launch_template" "ecs-optimized-ephemeral-storage-mounted" {

  name = "${var.project}-ECS-optimized-ephemeral-storage-mounted${var.suffix}"

  disable_api_termination = false
  image_id                = data.aws_ami.latest-amazon-ecs-optimized.image_id
  security_group_names    = []
  tags                    = var.tags

  key_name = var.key_pair

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = "true"
      encrypted             = "false"
      snapshot_id           = data.aws_ami.latest-amazon-ecs-optimized.root_snapshot_id
      volume_size           = 8
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.tags
  }

  user_data = data.local_file.mount_nvme2n1_mime.content_base64
}


resource "aws_batch_compute_environment" "ephemeral-storage" {
  compute_environment_name = "${var.project}-ephemeral-storage${var.suffix}"

  compute_resources {

    bid_percentage = 100
    ec2_key_pair   = var.key_pair

    instance_role       = aws_iam_instance_profile.ecs_instance_role.arn
    spot_iam_fleet_role = aws_iam_role.ec2_spot_fleet_role.arn

    instance_type = [
      "r5d", "c5d"
    ]

    max_vcpus = 256
    min_vcpus = 0

    security_group_ids = var.security_group_ids

    subnets = var.subnets

    launch_template {
      launch_template_id = aws_launch_template.ecs-optimized-ephemeral-storage-mounted.id
      version            = aws_launch_template.ecs-optimized-ephemeral-storage-mounted.latest_version
    }

    type = "SPOT"
    tags = local.tags
  }

  lifecycle {
    ignore_changes = [
      compute_resources.0.desired_vcpus,
    ]
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"
  state        = "ENABLED"
  depends_on   = [aws_iam_role_policy_attachment.aws_batch_service_role]


}