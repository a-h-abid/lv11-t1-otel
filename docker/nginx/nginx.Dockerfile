# syntax=docker/dockerfile:1

ARG NGINX_VERSION="1.27.3"
ARG NGINX_TAG_SUFFIX=""

FROM nginx:${NGINX_VERSION}${NGINX_TAG_SUFFIX}

LABEL maintainer="Ahmedul Haque Abid <a_h_abid@hotmail.com>"

USER root

# Set Timezone
ARG TIMEZONE="Asia/Dhaka"
ENV TZ="${TIMEZONE}"
RUN echo "${TIMEZONE}" > /etc/timezone \
    && rm /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

# Install APT Packages
ARG EXTRA_INSTALL_APT_PACKAGES=""
RUN apt-get update \
    && if [ ! -z "${EXTRA_INSTALL_APT_PACKAGES}" ]; then \
        apt-get install -y ${EXTRA_INSTALL_APT_PACKAGES} \
    ;fi \
    && apt-get clean -y \
    && apt-get autoremove -y \
    && rm -rf /tmp/* /var/tmp/*

# Add Nginx Configs
COPY ./docker/nginx/etc-nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./docker/nginx/etc-nginx/conf.d/*.conf /etc/nginx/conf.d/

# Remove the Entrypoints that comes with the image
RUN rm -rf /docker-entrypoint.d/*.sh

# Create Non-root User
ARG UID="1000"
ARG GID="1000"
RUN groupadd --gid ${GID} appuser \
    && useradd --uid ${UID} --create-home --system --comment "App User" --shell /bin/bash --gid appuser appuser \
    && install -d -o appuser -g appuser /home/appuser/appsrc

USER appuser

WORKDIR /home/appuser/appsrc

CMD ["nginx"]
