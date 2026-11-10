# User Documentation

## 1. Overview

This project provides a WordPress website running inside a Docker-based infrastructure.

The infrastructure contains three services:

* **NGINX**: HTTPS entry point.
* **WordPress + PHP-FPM**: website and PHP processing.
* **MariaDB**: WordPress database.

The services communicate through a private Docker network.

Only NGINX is accessible from outside the Docker network, through HTTPS on port 443.

## 2. Starting the project

From the root of the repository, run:

```bash
make
```

This builds the required Docker images and starts the infrastructure in detached mode.

You can also explicitly run:

```bash
make up
```

## 3. Stopping the project

To stop the containers:

```bash
make down
```

This stops and removes the containers without removing the persistent volumes.

## 4. Rebuilding the project

To completely remove containers and persistent volumes and rebuild the infrastructure:

```bash
make re
```

Be careful when using this command because removing the volumes removes the persistent application data stored in them.

## 5. Accessing the website

The website is available at:

```text
https://mgrandia.42.fr
```

The website is served through NGINX using HTTPS.

The infrastructure uses a locally generated certificate. Depending on the browser, a certificate warning may therefore be displayed.

## 6. Accessing the administration panel

The WordPress administration panel is available at:

```text
https://mgrandia.42.fr/wp-admin
```

The WordPress administrator account is the configured `mgrandia` account.

A second WordPress account named `editor` is also created with the editor role.

Passwords are not stored in this document.

## 7. Credentials

Sensitive credentials are stored locally in the `secrets/` directory:

```text
secrets/
├── credentials.txt
├── db_password.txt
└── db_root_password.txt
```

These files contain credentials required by the WordPress and MariaDB services.

They must not be published or committed to a public Git repository.

The `.env` file contains non-sensitive configuration values such as:

```text
DOMAIN_NAME
MYSQL_DATABASE
MYSQL_USER
```

## 8. Checking that the services are running

Use:

```bash
make ps
```

or:

```bash
docker ps
```

The expected services are:

```text
srcs-nginx-1
srcs-wordpress-1
srcs-mariadb-1
```

All three containers should be running.

NGINX should be the only container exposing a host port:

```text
443 -> 443
```

WordPress/PHP-FPM and MariaDB should not expose ports directly to the host.

## 9. Checking the Docker network

The services communicate through the Docker network created by the Compose project.

Use:

```bash
docker network ls
```

The project network should be present.

The containers can communicate using their service names:

```text
nginx -> wordpress
wordpress -> mariadb
```

## 10. Checking HTTPS

The website must be accessed using:

```text
https://mgrandia.42.fr
```

HTTP port 80 is not used as the public entry point.

The NGINX configuration uses:

```text
TLSv1.2
TLSv1.3
```

## 11. Checking persistent data

The project uses two persistent storage areas:

```text
/home/mgrandia/data/mariadb
/home/mgrandia/data/wordpress
```

The MariaDB data is stored separately from the WordPress website files.

The data persists when the containers are stopped and recreated, provided that the volumes are not deliberately removed.

## 12. Useful commands

### View running containers

```bash
docker ps
```

### View project containers

```bash
make ps
```

### View logs

```bash
make logs
```

### Stop the project

```bash
make down
```

### Start/rebuild the project

```bash
make
```

### List Docker volumes

```bash
docker volume ls
```

### List Docker networks

```bash
docker network ls
```

## 13. Important warning

Do not use:

```bash
make clean
```

or:

```bash
make re
```

if you need to preserve the current WordPress and MariaDB data.

These commands remove Docker volumes before rebuilding the infrastructure.

