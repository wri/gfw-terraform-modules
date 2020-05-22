#!/bin/bash
# 
# Builds a Docker image and pushes to an AWS ECR repository
#
# Invoked by the terraform-aws-ecr-docker-image Terraform module.
#
# Usage:
#
# # Acquire an AWS session token
# $ ./push.sh . 123456789012.dkr.ecr.us-west-1.amazonaws.com/hello-world latest
#

set -e

ROOT_DIR=${1:-.}
REPOSITORY_URL=$2
TAG=${3:-latest}
DOCKER_PATH="${4:-.}"
DOCKER_FILE="$DOCKER_PATH/${5:-Dockerfile}"

REGION="$(echo "$REPOSITORY_URL" | cut -d. -f4)"
IMAGE_NAME="$(echo "$REPOSITORY_URL" | cut -d/ -f2)"

pushd "$ROOT_DIR"

docker build -t "$IMAGE_NAME" -f "$DOCKER_FILE" .

$(aws ecr get-login --no-include-email --region "$REGION")
docker tag "$IMAGE_NAME" "$REPOSITORY_URL":"$TAG"
docker push "$REPOSITORY_URL":"$TAG"

popd