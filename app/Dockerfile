# syntax=docker/dockerfile:1
# Builds the Flutter *web* target and serves the static output with nginx.
# Android/iOS/desktop builds are not containerized — this image is web-only.
#
# Build: docker build -t app --build-arg API_BASE_URL=https://api.acalapp.site .
# Run:   docker run -d -p 80:80 --name app app

# Keep in sync with .devcontainer/Dockerfile's FLUTTER_VERSION
ARG FLUTTER_VERSION=3.44.4

FROM debian:bookworm-slim AS build
ARG FLUTTER_VERSION
ARG API_BASE_URL=http://localhost:3000

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y git curl unzip xz-utils ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter \
    && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter config --no-analytics --enable-web && flutter precache --web

WORKDIR /app

# Install dependencies first so this layer is cached unless pubspec changes.
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE_URL=${API_BASE_URL}

FROM nginx:1.27-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
