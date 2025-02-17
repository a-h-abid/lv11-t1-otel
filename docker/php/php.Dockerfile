# syntax=docker/dockerfile:1

ARG PHP_VERSION="8.4.4"

FROM php:${PHP_VERSION}-fpm

LABEL maintainer="Ahmedul Haque Abid <a_h_abid@hotmail.com>"

USER root

# Set Timezone
ARG TIMEZONE="Asia/Dhaka"
ENV TZ="${TIMEZONE}"
RUN echo "${TIMEZONE}" > /etc/timezone \
    && rm /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

# Clean junks made by docker team
RUN if [ -f "/etc/apt/apt.conf.d/docker-clean" ]; then \
        # Remove this file as it affects with buildkit's mount cache
        rm /etc/apt/apt.conf.d/docker-clean \
    ;fi \
    && if [ -f "/usr/local/etc/php-fpm.d/zz-docker.conf" ]; then \
        rm /usr/local/etc/php-fpm.d/zz-docker.conf \
    ;fi \
    && if [ -f "/usr/local/etc/php-fpm.d/docker.conf" ]; then \
        rm /usr/local/etc/php-fpm.d/docker.conf \
    ;fi

# Install APT Packages
ARG EXTRA_INSTALL_APT_PACKAGES=""
RUN apt-get update \
    && apt-get install -V -y --no-install-recommends --no-install-suggests \
        bc \
        curl \
        openssl \
        unzip \
        zip \
    && if [ ! -z "${EXTRA_INSTALL_APT_PACKAGES}" ]; then \
        apt install -y ${EXTRA_INSTALL_APT_PACKAGES} \
    ;fi \
    && mkdir /run/php \
    && apt clean -y \
    && apt autoremove -y \
    && rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/* /var/cache/apt/*

# Install PHP Extensions
ARG EXTRA_INSTALL_PHP_EXTENSIONS=""
ARG DOCKER_PHP_EXTENSION_VERSION="2.7.8"
RUN curl -L -o /usr/local/bin/install-php-extensions https://github.com/mlocati/docker-php-extension-installer/releases/download/${DOCKER_PHP_EXTENSION_VERSION}/install-php-extensions \
    && chmod a+x /usr/local/bin/install-php-extensions \
    && install-php-extensions \
        bcmath \
        exif \
        fileinfo \
        gd \
        gettext \
        grpc \
        intl \
        opcache \
        opentelemetry \
        pcntl \
        pdo \
        pdo_mysql \
        pdo_pgsql \
        protobuf \
        redis \
        sockets \
        swoole \
        uuid \
        xml \
        xmlreader \
        zip \
    && if [ ! -z "${EXTRA_INSTALL_PHP_EXTENSIONS}" ]; then \
        install-php-extensions ${EXTRA_INSTALL_PHP_EXTENSIONS} \
    ;fi \
    && mkdir -p -m 777 /tmp/xdebug

# PHP Composer Installation & Directory Permissions
ARG COMPOSER_VERSION="2.8.4"
RUN curl -L -o /usr/local/bin/composer https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar \
    && chmod ugo+x /usr/local/bin/composer \
    && composer --version

# PHP INI envs
ENV PHP_INI_OUTPUT_BUFFERING=4096 \
    PHP_INI_MAX_EXECUTION_TIME=60 \
    PHP_INI_MAX_INPUT_TIME=60 \
    PHP_INI_MEMORY_LIMIT="128M" \
    PHP_INI_DISPLAY_ERRORS="Off" \
    PHP_INI_DISPLAY_STARTUP_ERRORS="Off" \
    PHP_INI_POST_MAX_SIZE="2M" \
    PHP_INI_FILE_UPLOADS="On" \
    PHP_INI_UPLOAD_MAX_FILESIZE="2M" \
    PHP_INI_MAX_FILE_UPLOADS="2" \
    PHP_INI_ALLOW_URL_FOPEN="On" \
    PHP_INI_ERROR_LOG="" \
    PHP_INI_DATE_TIMEZONE="${TIMEZONE}" \
    PHP_INI_SESSION_SAVE_HANDLER="files" \
    PHP_INI_SESSION_SAVE_PATH="/tmp" \
    PHP_INI_SESSION_USE_STRICT_MODE=0 \
    PHP_INI_SESSION_USE_COOKIES=1 \
    PHP_INI_SESSION_USE_ONLY_COOKIES=1 \
    PHP_INI_SESSION_NAME="APP_SSID" \
    PHP_INI_SESSION_COOKIE_SECURE="On" \
    PHP_INI_SESSION_COOKIE_LIFETIME=0 \
    PHP_INI_SESSION_COOKIE_PATH="/" \
    PHP_INI_SESSION_COOKIE_DOMAIN="" \
    PHP_INI_SESSION_COOKIE_HTTPONLY="On" \
    PHP_INI_SESSION_COOKIE_SAMESITE="" \
    PHP_INI_SESSION_UPLOAD_PROGRESS_NAME="APP_UPLOAD_PROGRESS" \
    PHP_INI_OPCACHE_ENABLE=1 \
    PHP_INI_OPCACHE_ENABLE_CLI=0 \
    PHP_INI_OPCACHE_MEMORY_CONSUMPTION=128 \
    PHP_INI_OPCACHE_INTERNED_STRINGS_BUFFER=16 \
    PHP_INI_OPCACHE_MAX_ACCELERATED_FILES=100000 \
    PHP_INI_OPCACHE_MAX_WASTED_PERCENTAGE=25 \
    PHP_INI_OPCACHE_USE_CWD=0 \
    PHP_INI_OPCACHE_VALIDATE_TIMESTAMPS=1 \
    PHP_INI_OPCACHE_REVALIDATE_FREQ=0 \
    PHP_INI_OPCACHE_SAVE_COMMENTS=0 \
    PHP_INI_OPCACHE_ENABLE_FILE_OVERRIDE=1 \
    PHP_INI_OPCACHE_MAX_FILE_SIZE=0 \
    PHP_INI_OPCACHE_FAST_SHUTDOWN=1 \
    PHP_INI_XDEBUG_MODE="off" \
    PHP_INI_XDEBUG_OUTPUT_DIR="/tmp/xdebug/" \
    PHP_INI_XDEBUG_CLIENT_HOST="host.docker.internal" \
    PHP_INI_XDEBUG_CLIENT_PORT=10000 \
    PHP_INI_XDEBUG_START_WITH_REQUEST="yes"

COPY ./docker/php/etc-php/php.ini /usr/local/etc/php/php.ini

ENV PHPFPM_CONF_LOG_LEVEL="notice" \
    PHPFPM_CONF_LOG_LIMIT="8192" \
    PHPFPM_CONF_WWW_USER="appuser" \
    PHPFPM_CONF_WWW_GROUP="appuser" \
    PHPFPM_CONF_WWW_LISTEN=9000 \
    PHPFPM_CONF_WWW_LISTEN_OWNER="appuser" \
    PHPFPM_CONF_WWW_LISTEN_GROUP="appuser" \
    PHPFPM_CONF_WWW_LISTEN_MODE=0660 \
    PHPFPM_CONF_WWW_PM="static" \
    PHPFPM_CONF_WWW_PM_MAX_CHILDREN=2 \
    PHPFPM_CONF_WWW_PM_START_SERVERS=2 \
    PHPFPM_CONF_WWW_PM_MIN_SPARE_SERVERS=1 \
    PHPFPM_CONF_WWW_PM_MAX_SPARE_SERVERS=3 \
    PHPFPM_CONF_WWW_PM_PROCESS_IDLE_TIMEOUT="10s" \
    PHPFPM_CONF_WWW_PM_MAX_REQUESTS=0 \
    PHPFPM_CONF_WWW_CATCH_WORKERS_OUTPUT=1 \
    PHPFPM_CONF_WWW_FASTCGI_LOGGING=0

COPY ./docker/php/etc-phpfpm/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY ./docker/php/etc-phpfpm/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf

# Create Non-root User
ARG UID="1000"
ARG GID="1000"
RUN groupadd --gid ${GID} appuser \
    && useradd --uid ${UID} --create-home --system --comment "App User" --shell /bin/bash --gid appuser appuser \
    && mkdir -p /home/appuser/.composer/cache \
    && install -d -o appuser -g appuser /home/appuser/appsrc

USER appuser

WORKDIR /home/appuser/appsrc

VOLUME [ "/home/appuser/.composer/cache" ]

COPY --chown=appuser:appuser ./composer*.json ./composer*.lock* ./

ARG COMPOSER_INSTALL_OPTS="--profile"

RUN --mount=type=cache,target=/home/appuser/.composer/cache,sharing=locked,uid=${UID},gid=${GID} \
    --mount=type=secret,required=true,id=composer_auth,target=/home/appuser/appsrc/auth.json,uid=${UID},gid=${GID} \
    composer install ${COMPOSER_INSTALL_OPTS} --no-interaction --no-scripts --no-autoloader

# Copy Source Files
COPY --chown=appuser:appuser . .

RUN composer dump-autoload -o --classmap-authoritative

CMD [ "php-fpm" ]
