FROM ubuntu:19.10

MAINTAINER Phucnh <phucbkit@gmail.com>

ENV PHP_VERSION=7.3 \
    WORKDIR=/var/www/dev \
    DOCROOT=/var/www/dev/public \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y --no-install-recommends --no-install-suggests vim ca-certificates curl unzip git supervisor \
    nginx \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-bz2 \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php-redis \
    php-imagick && \
    curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    apt-get -y autoremove && \
    apt-get -y clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 80/tcp \
       443/tcp

RUN mkdir -p /var/log/nginx
RUN mkdir -p /etc/nginx/conf.d
RUN mkdir -p ${WORKDIR}
RUN mkdir -p ${DOCROOT}

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && ln -sf /dev/stderr /var/log/php-fpm.log

RUN mkdir -p /run/php

COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d
COPY run.sh /run.sh
RUN chmod 755 /run.sh

CMD ["/usr/bin/supervisord"]
