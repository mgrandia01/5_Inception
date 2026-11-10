#!/bin/bash

set -e

DOMAIN_NAME="${DOMAIN_NAME:-mgrandia.42.fr}"

sed -i "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

if [ ! -f /etc/nginx/ssl/server.crt ] || [ ! -f /etc/nginx/ssl/server.key ]; then
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/server.key \
        -out /etc/nginx/ssl/server.crt \
        -subj "/C=ES/ST=Madrid/L=Madrid/O=42/OU=Inception/CN=${DOMAIN_NAME}"
fi

exec nginx -g "daemon off;"
