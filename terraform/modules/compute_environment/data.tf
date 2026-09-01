data "aws_ami" "latest-amazon-ecs-optimized" {

  most_recent = true
  owners      = ["591542846629"] # AWS

  # Amazon Linux 2023 ECS-optimized AMI, for both architectures
  #
  # This module previously used the legacy Amazon Linux 1 ECS-optimized AMI
  # (amzn-ami-*-amazon-ecs-optimized) for x86_64, which reached end-of-life
  # on September 15, 2025, and Amazon Linux 2 (amzn2-ami-ecs-hvm-*-arm64-ebs)
  # reached end-of-life on June 30, 2026 -- after which
  # AWS Batch blocks creating new compute environments against AL2 AMIs
  # entirely. Both are past their EOL date as of this module version; AL2023
  # is the currently supported ECS-optimized AMI family for both
  # architectures (see aws/amazon-ecs-ami on GitHub for the authoritative
  # naming and release history).
  filter {
    name   = "name"
    values = ["al2023-ami-ecs-hvm-*-${var.architecture == "arm64" ? "arm64" : "x86_64"}"]
  }
  filter {
    name   = "architecture"
    values = [var.architecture == "arm64" ? "arm64" : "x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "batch_trust_policy" {
  template = file("${path.module}/templates/role-trust-policy.json")
  vars = {
    service = "batch"
  }
}

data "template_file" "ec2_trust_policy" {
  template = file("${path.module}/templates/role-trust-policy.json")
  vars = {
    service = "ec2"
  }
}

data "template_file" "spotfleet_trust_policy" {
  template = file("${path.module}/templates/role-trust-policy.json")
  vars = {
    service = "spotfleet"
  }
}

data "local_file" "mount_tmp_enable_swap" {
  filename = "${path.module}/user_data/mount_tmp_enable_swap.sh"
}
