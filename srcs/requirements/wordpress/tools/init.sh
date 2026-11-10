#!/bin/bash

set -e

MYSQL_PASSWORD=$(cat /run/secrets/db_password)

MYSQL_DATABASE="${MYSQL_DATABASE:-wordpress}"
MYSQL_USER="${MYSQL_USER:-wpuser}"
MYSQL_HOST="${MYSQL_HOST:-mariadb}"
DOMAIN_NAME="${DOMAIN_NAME:-mgrandia.42.fr}"

WP_ADMIN_USER=$(grep '^WP_ADMIN_USER=' /run/secrets/credentials | cut -d= -f2-)
WP_ADMIN_PASSWORD=$(grep '^WP_ADMIN_PASSWORD=' /run/secrets/credentials | cut -d= -f2-)
WP_USER=$(grep '^WP_USER=' /run/secrets/credentials | cut -d= -f2-)
WP_USER_PASSWORD=$(grep '^WP_USER_PASSWORD=' /run/secrets/credentials | cut -d= -f2-)

if [ ! -f /var/www/html/wp-config.php ]; then
    wp config create \
        --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="$MYSQL_HOST:3306" \
        --allow-root
fi

if ! wp core is-installed --path=/var/www/html --allow-root >/dev/null 2>&1; then
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="mgrandia@example.com" \
        --skip-email \
        --allow-root

    wp user create \
        "$WP_USER" \
        "editor@example.com" \
        --role=editor \
        --user_pass="$WP_USER_PASSWORD" \
        --path=/var/www/html \
        --allow-root
fi

exec php-fpm8.2 -F
