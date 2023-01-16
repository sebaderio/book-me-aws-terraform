#!/bin/sh
set -e

# USE CASE: Renew certbot certificates stored in the docker volume by running a command in the docker container.

cd /home/ec2-user/book-me
/usr/local/bin/docker-compose -f docker-compose.prod.yml run --rm certbot certbot renew

# Every time there is a change in the nginx configuration, nginx needs to be at least reloaded
# to make it use a new configuration instead of the cached, old one.
# It is suggested to reload instead of restarting to reduce the potential downtime of the app hosted through nginx.
/usr/local/bin/docker-compose -f docker-compose.prod.yml exec proxy nginx -s reload
