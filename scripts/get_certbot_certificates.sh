#!/bin/sh
set -e

# USE CASE: Generate first certbot certificates by running a command in the docker container.
#           Certificates will be stored in the docker volume.

cd /home/ec2-user/book-me
/usr/local/bin/docker-compose -f docker-compose.prod.yml run --rm certbot /opt/certify-init.sh
