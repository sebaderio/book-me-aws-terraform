#!/usr/bin/env bash

set -euxo pipefail

if [[ $# -ne 2 ]]; then
    echo "Illegal number of parameters."
    echo "Example usage: ./push_client_app_to_bucket.sh book-me-prod-client-app apiv2.bookme.tk"
fi

docker build -t $1 -f ../Dockerfile.prod ../.

docker run \
-e REACT_APP_REST_API_BASE_URL="https://$2" \
-e REACT_APP_WS_API_BASE_URL="wss://$2" \
-v /tmp/$1:/app/build \
$1

aws s3 cp --recursive /tmp/$1 "s3://$1"
