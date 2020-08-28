# Docker Container Registry

Terraform module to build & push a Docker image to an AWS ECR repository.

- Builds docker image from a Dockerfile 
- Pushes image to an AWS ECR repository
- Can customize the push and hash scripts
- Cleans up old images from the repository

`root_dir` is the directory in which you normally build your Dockerfile. Usually your Dockerfile will be located in `root_dir`. 
If your Dockerfile lives in a subfolder and you usually build your image using `docker build -t <tag> -f <path/to/Dockerfile> .`
you can specify the path to Dockerfile (`docker_path`) relative to `root_dir`.

## Requirements

| Name | Version |
|------|---------|
| terraform | >=0.12.13, < 0.14 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 2.45, < 4 |
| external | n/a |
| null | n/a |
| template | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| docker\_filename | Name of docker file | `string` | `"Dockerfile"` | no |
| docker\_path | Path to Docker image source, relative to root dir | `string` | `"."` | no |
| hash\_script | Path to script to generate hash of source contents | `string` | `""` | no |
| image\_name | Name of Docker image | `string` | n/a | yes |
| push\_script | Path to script to build and push Docker image | `string` | `""` | no |
| root\_dir | Root dir used in Dockerfile | `string` | `"."` | no |
| tag | Tag to use for deployed Docker image | `string` | `"latest"` | no |

## Outputs

| Name | Description |
|------|-------------|
| hash | Docker image source hash |
| repository\_url | ECR repository URL of Docker image |
| tag | Docker image tag |


## Usage

```terraform
module "container_registry" {
  source          = "git::git@github.com:wri/gfw-terraform-modules.git//modules/container_registry?ref=v0.1.3"
  image_name      = "my-project"
  root_dir        = "${path.root}/../"
  docker_path     = "docker/my-project"
  docker_filename = "project.dockerfile"
}
```


## Credits

This module fist publish by [Mathspace](https://github.com/mathspace/terraform-aws-ecr-docker-image) and later adopted for this project.
