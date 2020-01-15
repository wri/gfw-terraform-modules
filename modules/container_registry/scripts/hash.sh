#!/bin/bash
# 
# Calculates hash of Docker image source contents
#
# Invoked by the terraform-aws-ecr-docker-image Terraform module.
#
# Usage:
#
# $ ./hash.sh .
#

set -e

ROOT_DIR=${1:-.}
DOCKER_PATH=${2:-.}
IGNORE="${DOCKER_PATH}/.dockerignore"

pushd "$ROOT_DIR"

# Hash all source files of the Docker image
if [ -f "$IGNORE" ]; then
  # Exclude files listed in .dockerignore file
    file_hashes="$(
       find . -type f "$(printf "! -path %s " "$(cat "${IGNORE}")")" -exec md5sum {} \;
  )"
else
  # Exclude Python cache files, dot files
  file_hashes="$(
        find . -type f -not -name '*.pyc' -not -path './.**' -exec md5sum {} \;
  )"
fi

popd

hash="$(echo "$file_hashes" | md5sum | cut -d' ' -f1)"

echo '{ "hash": "'"$hash"'" }'
