# syntax=docker/dockerfile:1
FROM composer:2 AS composer-builder
WORKDIR /app
COPY composer.json composer.lock* ./
COPY packages/ packages/
RUN composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs --optimize-autoloader

FROM php:8.4-fpm-alpine AS runtime
RUN apk add --no-cache --virtual .build-deps \
        freetype-dev libjpeg-turbo-dev libpng-dev libzip-dev icu-dev linux-headers $PHPIZE_DEPS \
    && apk add --no-cache \
        nginx mariadb-client openssl freetype libjpeg-turbo libpng libzip icu-libs \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd intl mysqli pdo_mysql opcache zip \
    && pecl install redis \
    && docker-php-ext-enable opcache redis \
    && apk del .build-deps
RUN { \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.validate_timestamps=0'; \
    echo 'opcache.jit=tracing'; \
    echo 'opcache.jit_buffer_size=128M'; \
    echo 'upload_max_filesize=50M'; \
    echo 'post_max_size=50M'; \
    echo 'memory_limit=512M'; \
    echo 'max_execution_time=240'; \
    echo 'error_reporting=E_ALL & ~E_DEPRECATED'; \
    echo 'display_errors=Off'; \
    echo 'expose_php=Off'; \
    echo 'session.cookie_httponly=1'; \
    echo 'session.cookie_secure=1'; \
    echo 'session.cookie_samesite=Lax'; \
} > /usr/local/etc/php/conf.d/typo3.ini
WORKDIR /var/www
# COPY ordered: rarely-changed infra first, frequently-changed app code last
COPY docker/web/nginx.conf /etc/nginx/nginx.conf
COPY docker/web/php-fpm.conf /usr/local/etc/php-fpm.d/zz-typo3.conf
COPY docker/web/entrypoint.sh /entrypoint.sh
COPY data/fileadmin/ /seed/fileadmin/
COPY --from=composer-builder /app/vendor/ vendor/
COPY --from=composer-builder /app/public/ public/
COPY config/ config/
COPY packages/ packages/
RUN chmod +x /entrypoint.sh \
    && mkdir -p public/fileadmin public/typo3temp/assets/_processed_ var/log var/cache var/lock var/charset var/labels \
    && chown -R www-data:www-data public/fileadmin public/typo3temp var
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD wget -q -O /dev/null http://127.0.0.1/ || exit 1
ENTRYPOINT ["/entrypoint.sh"]
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]

FROM runtime AS dev
RUN apk add --no-cache $PHPIZE_DEPS linux-headers \
    && pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && apk del $PHPIZE_DEPS linux-headers
RUN { \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.revalidate_freq=0'; \
    echo 'opcache.jit=off'; \
    echo 'display_errors=On'; \
    echo 'error_reporting=E_ALL'; \
    echo 'xdebug.mode=debug,develop'; \
    echo 'xdebug.start_with_request=trigger'; \
    echo 'xdebug.client_host=host.docker.internal'; \
    echo 'xdebug.client_port=9003'; \
    echo 'xdebug.idekey=PHPSTORM'; \
} > /usr/local/etc/php/conf.d/zz-dev.ini
