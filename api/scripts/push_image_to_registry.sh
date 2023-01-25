#!/usr/bin/env bash

set -euxo pipefail

if [[ $# -ne 3 ]]; then
    echo "Illegal number of parameters."
    echo "Example usage: ./push_image_to_registry.sh eu-central-1 705130529207.dkr.ecr.eu-central-1.amazonaws.com book-me-prod-backend"
fi

aws ecr get-login-password --region $1 | docker login --username AWS --password-stdin $2

# This flag make it possible to skip building stages not required to build the specified target.
DOCKER_BUILDKIT=1
docker build -t $3 --target production ../.

docker tag $3 "$2/$3"

# Tag `latest` is added automatically when tag is not specified when building the image.
docker push "$2/$3:latest"

docker logout $2
