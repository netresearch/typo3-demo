# syntax=docker/dockerfile:1
FROM composer:2@sha256:4ed71c38c6d788eb4e4e3747b5332f5b40d5b5a6fcadd5062a1a70986a118e0a AS composer-builder
WORKDIR /app
COPY composer.json composer.lock* patches.lock.json ./
COPY packages/ packages/
# composer-patches applies patches/ during install; without the files in the
# build context it falls back to a remote download with a null host and dies.
COPY patches/ patches/
# The credential for the private Composer sources arrives as a BuildKit secret,
# NOT as a build arg. buildx records every build arg in the SLSA provenance it
# attaches to the pushed image, and this image is public: the previous `ARG
# COMPOSER_AUTH` published a working git.netresearch.de token in the attestation
# of all 1461 published versions, readable with a single `imagetools inspect`.
# The build layers never carried it — the builder stage is not shipped — which is
# exactly why reading `docker history` said "clean" and was the wrong instrument.
#
# A secret mount is visible only inside this RUN and appears in no layer, no arg
# and no attestation. Missing secret tolerated on purpose: a build without
# credentials still resolves everything public, which is what a fork's CI and a
# local `docker compose build` get.
RUN --mount=type=secret,id=composer_auth \
    COMPOSER_AUTH="$(cat /run/secrets/composer_auth 2>/dev/null || true)" \
    composer install --no-dev --prefer-dist --no-interaction --ignore-platform-reqs --optimize-autoloader

# Patch lochmueller/index: it casts a DateTimeImmutable date field to string
# directly ((string) $item->get('date')), which throws and aborts index:queue —
# that blocks nr-ai-search content vectorization on bootstrap-package timeline
# content. Idempotent str_replace; upstream fix pending. Remove once released.
COPY docker/web/patch-lochmueller-index.php /tmp/patch-lochmueller-index.php
RUN php /tmp/patch-lochmueller-index.php && rm -f /tmp/patch-lochmueller-index.php

# mfd/ai-filemetadata's upload listener must run only in a backend request: a
# CLI job that writes images to FAL (nr_repurpose) would otherwise call the
# vision model for each image, and a failed call aborts the job. The composer
# patch patches/mfd-ai-filemetadata-application-type.patch carries that guard,
# and it catches a failed generation so that it cannot fail the upload.
# patches/mfd-ai-filemetadata-fal-adapter-log.patch makes FalAdapter log its
# DataHandler errors instead of var_dump()ing HTML into the upload response.
# This check fails the build if the installed extension lacks any of them.
RUN listener=vendor/mfd/ai-filemetadata/Classes/EventListener/EnrichFileMetadataAfterCreation.php \
    && adapter=vendor/mfd/ai-filemetadata/Classes/Services/FalAdapter.php \
    && grep -qF 'ApplicationType::fromRequest($request)->isBackend()' "$listener" \
    && grep -qF '!$this->isBackendRequest()' "$listener" \
    && grep -qF "'Alt text generation on upload failed for file {fileUid}" "$listener" \
    && test -f "$adapter" \
    && ! grep -qF 'DebuggerUtility::var_dump' "$adapter" \
    || { echo "mfd/ai-filemetadata lacks the backend-only guard, the catch" >&2; \
         echo "around generation, or the FalAdapter logging patch." >&2; \
         echo "Check that the patches/mfd-ai-filemetadata-*.patch files still apply." >&2; \
         exit 1; }

# The site package replaces bootstrap_package's Media/Rendering/Image.html with
# a copy of the 16.0.1 file that adds the decorative-image branch. The copy wins
# for every image in Text & Images, Text & Media and Images, so a change upstream
# (srcset, lazy loading, a bugfix) would never reach the site, and Renovate merges
# bootstrap_package updates on its own. This check fails the build, which is the
# required check, as soon as the installed original differs from the one the copy
# was made from. To pass it: carry the upstream change into the copy, then record
# the new file's sha256 here and the version in the copy's comment.
COPY docker/web/bootstrap-image-partial.sha256 /tmp/bootstrap-image-partial.sha256
RUN sha256sum -c /tmp/bootstrap-image-partial.sha256 \
    || { echo "bootstrap_package changed Media/Rendering/Image.html." >&2; \
         echo "Carry the change into the site package's copy of that partial," >&2; \
         echo "update the version in the copy's comment," >&2; \
         echo "and record the new checksum in docker/web/bootstrap-image-partial.sha256." >&2; \
         exit 1; }

FROM php:8.5-fpm-alpine@sha256:4c2818074ec49f6abe46620f3965e0cb75bc3a5f2b417edd1aacaba6f091c40e AS runtime
# Both imagick and GD are built with WebP and AVIF: TYPO3 picks its processor
# from the install-wide setting, and core's imageFileConversionFormats can only
# deliver a modern format if the one in use can encode it. AVIF reaches
# ImageMagick through the HEIF coder, hence imagemagick-heic. Without a working
# AVIF delegate ImageMagick writes empty .avif files instead of failing.
#
# The encoders were originally added for nr_image_optimize. They stay after its
# removal because core's conversion needs exactly the same thing — the WebP
# delivery the build asserts comes from core.
RUN --mount=type=bind,from=ghcr.io/php/pie:1.5.2-bin@sha256:a254c78b51ca34daef0541fa1cf0147385c93ba5ca799868392275d947f00fe7,source=/pie,target=/usr/local/bin/pie \
    apk add --no-cache --virtual .build-deps \
        freetype-dev libjpeg-turbo-dev libpng-dev libzip-dev icu-dev linux-headers \
        libwebp-dev libavif-dev imagemagick-dev $PHPIZE_DEPS \
    && apk add --no-cache \
        nginx mariadb-client openssl freetype libjpeg-turbo libpng libzip icu-libs \
        imagemagick imagemagick-webp imagemagick-heic libwebp libavif \
        ffmpeg poppler-utils chromium font-liberation nodejs \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
    && docker-php-ext-install -j$(nproc) gd intl mysqli pdo_mysql zip exif \
    && pie install --no-interaction phpredis/phpredis imagick/imagick \
    && docker-php-ext-enable redis imagick \
    && apk del .build-deps
RUN { \
    echo 'opcache.memory_consumption=256'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=20000'; \
    echo 'opcache.validate_timestamps=0'; \
    echo 'opcache.jit=off'; \
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
    echo 'session.use_strict_mode=1'; \
    echo 'session.upload_progress.enabled=0'; \
} > /usr/local/etc/php/conf.d/typo3.ini
WORKDIR /var/www
# COPY ordered: rarely-changed infra first, frequently-changed app code last
COPY docker/web/nginx.conf /etc/nginx/nginx.conf
COPY docker/web/security-headers.conf /etc/nginx/security-headers.conf
COPY docker/web/php-fpm.conf /usr/local/etc/php-fpm.d/zz-typo3.conf
COPY docker/web/entrypoint.sh /entrypoint.sh
COPY data/fileadmin/ /seed/fileadmin/
# _temp_ and _recycler_ hold what TYPO3 writes on the fly (import/export dumps,
# deleted files). In the seed they would be copied into every instance on every
# boot, which is how two .t3d dumps of the demo's records became public. Only
# the placeholder files TYPO3 creates there itself may be committed.
RUN stray=$(find /seed/fileadmin \( -path '*/_temp_/*' -o -path '*/_recycler_/*' \) -type f ! -name index.html ! -name .htaccess) \
    && if [ -n "$stray" ]; then printf 'data/fileadmin/ carries files in a _temp_ or _recycler_ folder:\n%s\n' "$stray" >&2; exit 1; fi
COPY data/seed-*.sql data/
COPY --from=composer-builder /app/vendor/ vendor/
COPY --from=composer-builder /app/public/ public/
COPY config/ config/
COPY packages/ packages/
# The Open Graph card is served from a fixed docroot path rather than from the
# extension's published /_assets/<hash>/ directory, because a meta tag needs an
# absolute URL that can be written down. fileadmin was not an option either:
# entrypoint.sh seeds it only into an EMPTY directory, so a file added to
# data/fileadmin/ would never reach an instance that already has one.
# The source of truth stays in the site package next to its HTML source.
COPY packages/netresearch-demo-site/Resources/Public/Images/og-card.png public/og-card.png
# Second half of this instruction: nr-repurpose's HTML -> PNG renderer is a Node
# script with one dependency of its own, shipped with the extension as
# package.json/package-lock.json. Nothing installed it, so every schaubild and
# story slide failed with "Cannot find module 'playwright-core'" while the job
# still reported progress 100. chromium, nodejs and CHROMIUM_PATH were already
# here; only the install was missing.
#
# npm is build-time only and removed again: it is not needed at runtime and the
# renderer never installs anything itself.
#
# --ignore-scripts: no lifecycle script runs during the install. playwright-core
# does not need one (browser downloads belong to the `playwright` package, which
# this is not), so nothing is lost and an install-time script cannot execute.
#
# The `require` at the end is a gate, not decoration. A silent no-op install
# would otherwise ship exactly the state this fixes, and the failure would only
# reappear on the instance.
RUN chmod +x /entrypoint.sh \
    && mkdir -p public/fileadmin public/typo3temp/assets/_processed_ var/log var/cache var/lock var/charset var/labels \
    && chown -R www-data:www-data public/fileadmin public/typo3temp var \
    && apk add --no-cache --virtual .node-deps npm \
    && cd vendor/netresearch/nr-repurpose/Resources/Private/NodeRenderer \
    && PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 npm ci --omit=dev --ignore-scripts --no-audit --no-fund \
    && node -e "require('playwright-core'); console.log('playwright-core resolves')" \
    && cd /var/www \
    && apk del .node-deps

# nr-repurpose renders HTML -> PNG via the system chromium (no Playwright download)
ENV CHROMIUM_PATH=/usr/bin/chromium-browser \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
EXPOSE 80
HEALTHCHECK --interval=30s --timeout=5s --start-period=300s --retries=3 \
    CMD wget -q -O /dev/null --header="Host: ${TYPO3_DOMAIN:-localhost}" http://127.0.0.1/ || exit 1
# Root on purpose: entrypoint.sh chowns var, fileadmin, typo3temp and
# config/system (all but typo3temp are named volumes in compose.yml) to
# www-data before it execs the CMD. The php-fpm
# pool workers run as www-data (the base image's www.conf) and the nginx
# workers as nginx (the Alpine package's compiled-in --user).
# nosemgrep: dockerfile.security.missing-user-entrypoint.missing-user-entrypoint
ENTRYPOINT ["/entrypoint.sh"]
# nosemgrep: dockerfile.security.missing-user.missing-user
CMD ["sh", "-c", "php-fpm -D && nginx -g 'daemon off;'"]

FROM runtime AS dev
RUN { \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.revalidate_freq=0'; \
    echo 'display_errors=On'; \
    echo 'error_reporting=E_ALL'; \
} > /usr/local/etc/php/conf.d/zz-dev.ini
