# syntax=docker/dockerfile:1
FROM composer:2 AS composer-builder
WORKDIR /app
COPY composer.json composer.lock* ./
COPY packages/ packages/
RUN composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs

FROM php:8.4-fpm-alpine AS runtime
RUN apk add --no-cache \
    nginx mariadb-client freetype-dev libjpeg-turbo-dev libpng-dev libzip-dev icu-dev linux-headers \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd intl mysqli pdo_mysql opcache zip \
    && docker-php-ext-enable opcache
RUN { \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.validate_timestamps=0'; \
    echo 'upload_max_filesize=50M'; \
    echo 'post_max_size=50M'; \
    echo 'memory_limit=512M'; \
    echo 'max_execution_time=240'; \
    echo 'error_reporting=E_ALL & ~E_DEPRECATED'; \
    echo 'display_errors=Off'; \
} > /usr/local/etc/php/conf.d/typo3.ini
WORKDIR /var/www
COPY --from=composer-builder /app/vendor/ vendor/
COPY --from=composer-builder /app/public/ public/
COPY config/ config/
COPY packages/ packages/
COPY data/fileadmin/ /seed/fileadmin/
COPY docker/web/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/web/php-fpm.conf /usr/local/etc/php-fpm.d/zz-typo3.conf
COPY docker/web/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN mkdir -p public/fileadmin public/typo3temp/assets/_processed_ var/log var/cache var/lock var/charset var/labels \
    && chown -R www-data:www-data public/fileadmin public/typo3temp var
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
    CMD wget -q --spider http://127.0.0.1/ || exit 1
ENTRYPOINT ["/entrypoint.sh"]
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]
