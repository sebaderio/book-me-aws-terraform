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

# Useful resources:
# 1. https://stackoverflow.com/questions/58695853/docker-image-tagging-in-ecr
#    You can add multiple tags to the image and push all to the ECR repository. AWS CLI, ECR or whatever
#    is smart enough to not push the same image twice. Thanks to this you can have `latest` tag
#    and separate, `commit hash` tag to run the specific version of the pushed image. Make sure that image
#    tag mutability is enabled. Otherwise you may get an error when pushing another image with `latest` tag.
