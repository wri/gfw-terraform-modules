data "aws_ami" "latest-amazon-ecs-optimized" {

  most_recent = true
  owners      = ["591542846629"] # AWS

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
