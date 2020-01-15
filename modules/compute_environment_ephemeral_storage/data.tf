data "aws_ami" "latest-amazon-ecs-optimized" {

  most_recent = true
  owners      = ["591542846629"] # AWS

  filter {
    name   = "name"
    values = ["amzn-ami-*-amazon-ecs-optimized"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
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

data "local_file" "mount_nvme2n1_mime" {
  filename = "${path.module}/user_data/mount_nvme2n1_mime.sh"
}
