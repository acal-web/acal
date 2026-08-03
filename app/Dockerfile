# syntax=docker/dockerfile:1
# Builds the Flutter *web* target and serves the static output with nginx.
# Android/iOS/desktop builds are not containerized — this image is web-only.
#
# API_BASE_URL is NOT baked in at build time: the same image is meant to be
# published once and deployed to any environment. It's read at container
# start from the API_BASE_URL env var (see docker/docker-entrypoint.d/) and
# written into config.js, loaded by web/index.html before the Flutter bundle.
#
# Build: docker build -t app .
# Run:   docker run -d -p 80:80 -e API_BASE_URL=https://api.acalapp.site --name app app

# Keep in sync with .devcontainer/Dockerfile's FLUTTER_VERSION
ARG FLUTTER_VERSION=3.44.4

FROM debian:bookworm-slim AS build
ARG FLUTTER_VERSION

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y git curl unzip xz-utils ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    useradd --create-home --shell /bin/bash flutter

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter \
    && chown -R flutter:flutter /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# The Flutter tool warns (and some of its checks refuse to run) as root.
USER flutter
RUN git config --global --add safe.directory /opt/flutter \
    && flutter config --no-analytics --enable-web \
    && flutter precache --web

WORKDIR /app

# Install dependencies first so this layer is cached unless pubspec changes.
COPY --chown=flutter:flutter pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY --chown=flutter:flutter . .
RUN flutter build web --release

FROM nginx:1.27-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY docker/docker-entrypoint.d/40-runtime-config.sh /docker-entrypoint.d/40-runtime-config.sh
RUN chmod +x /docker-entrypoint.d/40-runtime-config.sh

EXPOSE 80
