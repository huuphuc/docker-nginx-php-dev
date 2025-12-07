FROM ubuntu:22.04

MAINTAINER Phucnh <phucbkit@gmail.com>

ARG PHP_VERSION=8.4
ENV WORKDIR=/var/www/dev \
    DOCROOT=/var/www/dev/public \
    DEBIAN_FRONTEND=noninteractive

RUN echo "PHP-${PHP_VERSION}"

RUN apt update && apt -y upgrade && \
    apt-get install -y --no-install-recommends --no-install-suggests vim curl unzip git supervisor
RUN apt install -y lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common && \
    add-apt-repository ppa:ondrej/php && apt update -y
RUN apt install -y \
    nginx \
    php${PHP_VERSION} \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-bz2 \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-imagick && \
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

#RUN update-alternatives --set php /usr/bin/php${PHP_VERSION}
#RUN update-alternatives --set phar /usr/bin/phar${PHP_VERSION}
#RUN update-alternatives --set phar.phar /usr/bin/phar.phar${PHP_VERSION}
#RUN update-alternatives --set phpize /usr/bin/phpize${PHP_VERSION}
#RUN update-alternatives --set php-config /usr/bin/php-config${PHP_VERSION}

RUN ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && ln -sf /dev/stderr /var/log/php${PHP_VERSION}-fpm.log \
    && ln -sf /dev/stderr /var/log/php-fpm.log

RUN mkdir -p /run/php

COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d
COPY www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY 99-opcache.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-opcache.ini
COPY 99-opcache.ini /etc/php/${PHP_VERSION}/fpm/conf.d/99-opcache.ini
COPY 99-memory.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-memory.ini
COPY 99-memory.ini /etc/php/${PHP_VERSION}/fpm/conf.d/99-memory.ini
COPY index.php ${DOCROOT}/index.php

CMD ["/usr/bin/supervisord"]
