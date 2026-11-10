# Developer Documentation

## 1. Project overview

This project builds a three-service infrastructure using Docker Compose:

```text
NGINX
  |
  | FastCGI
  v
WordPress + PHP-FPM
  |
  | MySQL
  v
MariaDB
```

All three services run in dedicated Docker containers and communicate through the `inception` Docker network.

NGINX is the only public entry point and exposes port 443.

## 2. Prerequisites

The development environment requires:

* Linux virtual machine
* Docker
* Docker Compose
* GNU Make
* Git

The project is designed to be executed from:

```text
~/inception
```

## 3. Project structure

```text
inception/
├── .gitignore
├── Makefile
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── .dockerignore
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── wordpress/
            ├── .dockerignore
            ├── Dockerfile
            ├── conf/
            └── tools/
```

## 4. Docker images

Each service has its own Dockerfile.

All three images are based on Debian Bookworm.

### NGINX

The NGINX Dockerfile installs:

* NGINX
* OpenSSL

It copies:

```text
conf/nginx.conf
tools/init.sh
```

into the image.

The initialization script generates the TLS certificate when necessary and starts NGINX in the foreground.

### WordPress

The WordPress Dockerfile installs:

* PHP-FPM
* PHP MySQL extension
* PHP cURL
* PHP GD
* PHP mbstring
* PHP XML
* PHP ZIP
* curl

WP-CLI and WordPress are downloaded during image construction.

The WordPress initialization script configures WordPress and starts PHP-FPM in the foreground.

### MariaDB

The MariaDB Dockerfile installs MariaDB Server.

It also creates the MariaDB runtime directory and copies:

```text
conf/50-server.cnf
tools/init.sh
```

into the image.

The initialization script initializes the database when required and then starts MariaDB in the foreground.

## 5. Environment configuration

Non-sensitive configuration is stored in:

```text
srcs/.env
```

The current configuration contains:

```text
DOMAIN_NAME=mgrandia.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
```

Passwords and other sensitive credentials are not stored in `.env`.

## 6. Docker secrets

Sensitive credentials are stored under:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

Docker Compose exposes these secrets to the relevant containers.

Inside the containers they are available under:

```text
/run/secrets/
```

The WordPress initialization script reads the database password from:

```text
/run/secrets/db_password
```

and reads the WordPress administrator and editor credentials from:

```text
/run/secrets/credentials
```

MariaDB reads:

```text
/run/secrets/db_password
/run/secrets/db_root_password
```

Developers must never commit real credentials to Git.

## 7. Docker Compose

The Compose configuration is located at:

```text
srcs/docker-compose.yml
```

It defines three services:

```text
mariadb
wordpress
nginx
```

and the project network:

```text
inception
```

The service dependencies are based on network communication rather than host-exposed ports.

### NGINX

NGINX:

* joins the `inception` network;
* exposes port 443;
* receives the WordPress volume as read-only;
* communicates with WordPress through port 9000.

### WordPress

WordPress:

* joins the `inception` network;
* stores its files in the WordPress persistent volume;
* communicates with MariaDB using the hostname `mariadb`;
* runs PHP-FPM on port 9000.

### MariaDB

MariaDB:

* joins the `inception` network;
* stores database files in the MariaDB persistent volume;
* is not exposed directly to the host.

## 8. Building the project

The Makefile defines the main development commands.

### Build and start

```bash
make
```

or:

```bash
make up
```

The command runs Docker Compose with:

```bash
docker compose -f srcs/docker-compose.yml up -d --build
```

### Build only

```bash
make build
```

### Stop containers

```bash
make down
```

### Remove containers and volumes

```bash
make clean
```

### Remove containers, volumes and images

```bash
make fclean
```

### Full rebuild

```bash
make re
```

This executes:

```bash
docker compose -f srcs/docker-compose.yml down -v --rmi all
docker compose -f srcs/docker-compose.yml up -d --build
```

### View logs

```bash
make logs
```

### View Compose status

```bash
make ps
```

## 9. Container management

The containers can also be inspected directly with Docker.

```bash
docker ps
```

The expected containers are:

```text
srcs-nginx-1
srcs-wordpress-1
srcs-mariadb-1
```

To inspect logs for a particular service:

```bash
docker logs srcs-nginx-1
docker logs srcs-wordpress-1
docker logs srcs-mariadb-1
```

To inspect the Compose services:

```bash
docker compose -f srcs/docker-compose.yml ps
```

## 10. Network management

The project creates a dedicated Docker network.

List networks with:

```bash
docker network ls
```

Inspect the project network with:

```bash
docker network inspect srcs_inception
```

The containers use Docker's internal DNS and service names.

The relevant communication paths are:

```text
NGINX -> wordpress:9000
WordPress -> mariadb:3306
```

No `network: host` configuration or Docker `links` are used.

## 11. Persistent storage

The project defines two Docker volumes:

```text
mariadb_data
wordpress_data
```

They are used as follows:

```text
mariadb_data
    -> /var/lib/mysql

wordpress_data
    -> /var/www/html
```

The configured host storage locations are:

```text
/home/mgrandia/data/mariadb
/home/mgrandia/data/wordpress
```

The WordPress volume is mounted read-only inside NGINX:

```text
wordpress_data:/var/www/html:ro
```

This allows NGINX to serve the website files without requiring write access to the WordPress volume.

## 12. Volume management

List volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

Do not remove the volumes manually if the WordPress installation and database need to be preserved.

The following Makefile targets remove volumes:

```bash
make clean
make fclean
make re
```

## 13. NGINX and TLS

The NGINX configuration is located at:

```text
srcs/requirements/nginx/conf/nginx.conf
```

The initialization script is:

```text
srcs/requirements/nginx/tools/init.sh
```

The script replaces the `${DOMAIN_NAME}` placeholder with the configured domain.

It then generates:

```text
/etc/nginx/ssl/server.crt
/etc/nginx/ssl/server.key
```

when they do not already exist.

The certificate is generated with OpenSSL.

NGINX accepts:

```text
TLSv1.2
TLSv1.3
```

and listens on:

```text
443
```

PHP requests are passed to:

```text
wordpress:9000
```

## 14. PHP-FPM

The PHP-FPM pool configuration is:

```text
srcs/requirements/wordpress/conf/www.conf
```

PHP-FPM runs as:

```text
www-data
```

and listens on:

```text
9000
```

The WordPress initialization script starts PHP-FPM in the foreground:

```text
php-fpm8.2 -F
```

This provides the main foreground process for the container.

## 15. WordPress initialization

The WordPress initialization script:

```text
srcs/requirements/wordpress/tools/init.sh
```

performs the following operations:

1. Reads the database password from the Docker secret.
2. Reads the WordPress credentials from the credentials secret.
3. Creates `wp-config.php` when necessary.
4. Checks whether WordPress is already installed.
5. Installs WordPress if required.
6. Creates the administrator account.
7. Creates the editor account.
8. Starts PHP-FPM.

The configured WordPress domain is:

```text
https://mgrandia.42.fr
```

## 16. MariaDB initialization

The MariaDB initialization script is:

```text
srcs/requirements/mariadb/tools/init.sh
```

On first initialization it:

1. Initializes the MariaDB data directory.
2. Starts MariaDB temporarily with networking disabled.
3. Waits for the server to become available.
4. Creates the WordPress database.
5. Creates the WordPress database user.
6. Grants database privileges.
7. Sets the root password.
8. Shuts down the temporary MariaDB process.
9. Starts MariaDB normally.

When the database directory already exists, the initialization process is skipped and MariaDB starts normally.

## 17. Restart policy

The three services use:

```yaml
restart: unless-stopped
```

This allows Docker to restart a container when it exits unexpectedly, while still allowing an intentional stop to remain stopped.

## 18. Troubleshooting

### Check all services

```bash
docker ps
```

### Check Compose status

```bash
make ps
```

### Check logs

```bash
make logs
```

### Check individual logs

```bash
docker logs srcs-nginx-1
docker logs srcs-wordpress-1
docker logs srcs-mariadb-1
```

### Check the network

```bash
docker network inspect srcs_inception
```

### Check volumes

```bash
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
```

### Rebuild

If the images or configuration need to be rebuilt:

```bash
make re
```

Remember that this removes the existing Docker volumes.

## 19. Development notes

The three services should remain independent.

NGINX should handle HTTPS and forward PHP requests to PHP-FPM.

WordPress should communicate with MariaDB through the Docker network rather than through a host-exposed database port.

MariaDB should not be exposed directly to the host.

Configuration and credentials should remain separated:

```text
Non-sensitive configuration
        -> srcs/.env

Sensitive credentials
        -> Docker secrets
```

The Dockerfiles should remain responsible for building the service images, while initialization scripts should handle runtime initialization and start the main service process.

