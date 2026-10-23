FROM ubuntu:22.04

LABEL org.opencontainers.image.authors="huuphuc <phucbkit@gmail.com>" \
      org.opencontainers.image.description="Nginx + PHP-FPM image for local development" \
      org.opencontainers.image.source="https://github.com/huuphuc/docker-nginx-php-dev"

ENV DEBIAN_FRONTEND=noninteractive \
    WORKDIR=/var/www/dev \
    DOCROOT=/var/www/dev/public

# Base tools, nginx and the ondrej/php PPA. Kept independent of PHP_VERSION so
# this layer is shared between builds of different PHP versions.
RUN apt-get update -y && apt-get -y upgrade \
    && apt-get install -y --no-install-recommends \
       ca-certificates vim curl unzip git supervisor nginx \
       gnupg2 software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get purge -y --auto-remove software-properties-common gnupg2 \
    && rm -rf /etc/nginx/sites-enabled/default /var/www/html \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && rm -rf /var/lib/apt/lists/*

ARG PHP_VERSION=8.5

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-bz2 \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-imagick \
    && ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm \
    && ln -sf /dev/stderr /var/log/php${PHP_VERSION}-fpm.log \
    && mkdir -p /run/php ${DOCROOT} \
    && chown -R www-data:www-data ${WORKDIR} \
    && apt-get -y clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer
COPY ./configs/nginx.conf /etc/nginx/nginx.conf
COPY ./configs/default.conf /etc/nginx/conf.d/default.conf
COPY ./configs/www.conf /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
COPY ./configs/php.ini /etc/php/${PHP_VERSION}/fpm/conf.d/99-custom.ini
COPY ./configs/php.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-custom.ini
COPY ./configs/supervisor.conf /etc/supervisor/conf.d/dev.conf
COPY --chown=www-data:www-data ./public/ ${DOCROOT}/

WORKDIR ${WORKDIR}

EXPOSE 80/tcp

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
