#!/bin/bash

set -e

echo "Checking for dhparams.pem"
if [ ! -f "/vol/proxy/ssl-dhparams.pem" ]; then
  echo "dhparams.pem does not exist - creating it"
  openssl dhparam -out /vol/proxy/ssl-dhparams.pem 2048
fi

# Avoid replacing these with envsubst - left here just as a reference how to use envsubst
# export host=\$host
# export request_uri=\$request_uri

echo "Checking for fullchain.pem"
if [ ! -f "/etc/letsencrypt/live/api.bookme.tk/fullchain.pem" ] || \
   [ ! -f "/etc/letsencrypt/live/bookme.tk/fullchain.pem" ] || \
   [ ! -f "/etc/letsencrypt/live/monitoring.bookme.tk/fullchain.pem" ]
then
  echo "No SSL certs, enabling HTTP only..."
  # envsubst < /etc/nginx/default.conf.tpl > /etc/nginx/conf.d/default.conf
  cp /etc/nginx/default.conf.tpl /etc/nginx/conf.d/default.conf
else
  echo "SSL certs exist, enabling HTTPS..."
  # envsubst < /etc/nginx/default-ssl.conf.tpl > /etc/nginx/conf.d/default.conf
  cp /etc/nginx/default-ssl.conf.tpl /etc/nginx/conf.d/default.conf
fi

nginx -g 'daemon off;'
