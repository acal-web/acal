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
# Run:   docker run -d -p 80:8080 -e API_BASE_URL=https://api.acalapp.site --name app app

# Keep in sync with .devcontainer/Dockerfile's FLUTTER_VERSION
ARG FLUTTER_VERSION=3.47.2

# debian:bookworm-slim
FROM debian@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171 AS build
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
RUN flutter pub get --enforce-lockfile

COPY --chown=flutter:flutter . .
RUN flutter build web --release

# nginx-unprivileged runs the whole process tree (master and workers) as the
# non-root "nginx" user on port 8080, unlike the stock nginx image whose
# master process needs root to bind port 80.
# nginxinc/nginx-unprivileged:1.27-alpine
FROM nginxinc/nginx-unprivileged@sha256:65e3e85dbaed8ba248841d9d58a899b6197106c23cb0ff1a132b7bfe0547e4c0
COPY --from=build --chown=nginx:nginx /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --chmod=755 docker/docker-entrypoint.d/40-runtime-config.sh /docker-entrypoint.d/40-runtime-config.sh

# Base image already defaults to this non-root user; declared explicitly so
# the image doesn't appear to run as root to tools that only read this file.
USER nginx

EXPOSE 8080
