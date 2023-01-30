#!/usr/bin/env bash

set -euxo pipefail

if [[ $# -ne 3 ]]; then
    echo "Illegal number of parameters."
    echo "Example usage: ./push_config_file_to_bucket.sh ../../service-config/api/production.env book-me-prod-config /service-config/api/production.env"
fi

aws s3 cp $1 "s3://$2$3"
