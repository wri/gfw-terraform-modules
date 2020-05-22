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

- Docker
- md5sum (e.g. from `brew install md5sha1sum`)

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

## Inputs

| Name           | Description                                        |  Type  |  Default     | Required |
| -------------- | -------------------------------------------------- | :----: | :----------: | :------: |
| image_name     | Name of Docker image                               | string |     n/a      |   yes    |
| root_dir       | Path to folder used as root dir in Dockerfile      | string |     n/a      |   yes    |
| docker_path    | Path to Dockerfile folder relative to root_dir     | string |      .       |    no    |
| docker_filename| Name of Dockerfile                                 | string | "Dockerfile" |    no    |
| tag            | Tag to use for deployed Docker image               | string |  `"latest"`  |    no    |
| hash_script    | Path to script to generate hash of source contents | string |     `""`     |    no    |
| push_script    | Path to script to build and push Docker image      | string |     `""`     |    no    |


## Outputs

| Name           | Description                        |
| -------------- | ---------------------------------- |
| hash           | Docker image source hash           |
| repository_url | ECR repository URL of Docker image |
| tag            | Docker image tag                   |

## Credits

This module fist publish by [Mathspace](https://github.com/mathspace/terraform-aws-ecr-docker-image) and later adopted for this project.
