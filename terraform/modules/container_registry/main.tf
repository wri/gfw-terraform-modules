data "template_file" "ecr_lifecycle_policy" {
  template = file("${path.module}/policies/lifecycle.json")
  vars = {
    tag = var.tag
  }
}

# Calculate hash of the Docker image source contents
data "external" "hash" {
  program = [coalesce(var.hash_script, "${path.module}/scripts/hash.sh"), var.root_dir, var.docker_path]
}

resource "aws_ecr_repository" "repo" {
  name = lower(var.image_name)
}

resource "aws_ecr_lifecycle_policy" "repo-policy" {
  repository = aws_ecr_repository.repo.name
  policy     = data.template_file.ecr_lifecycle_policy.rendered
}

# Build and push the Docker image whenever the hash changes
resource "null_resource" "push" {
  triggers = {
    hash = lookup(data.external.hash.result, "hash")
  }

  provisioner "local-exec" {
    command     = "${coalesce(var.push_script, "${path.module}/scripts/push.sh")} ${var.root_dir} ${aws_ecr_repository.repo.repository_url} ${var.tag} ${var.docker_path} ${var.docker_filename}"
    interpreter = ["bash", "-c"]
  }
}