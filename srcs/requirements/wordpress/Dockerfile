FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y \
        php-fpm \
        php-mysql \
        php-curl \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip \
        curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/html

RUN curl -O https://wordpress.org/latest.tar.gz && \
    tar -xzf latest.tar.gz --strip-components=1 -C /var/www/html && \
    rm latest.tar.gz

RUN chown -R www-data:www-data /var/www/html

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["/usr/local/bin/init.sh"]
