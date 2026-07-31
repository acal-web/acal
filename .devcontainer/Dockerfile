# Combined dev image for the acal2 monorepo: Ruby/Rails (api/) + Flutter/Dart (app/).
# Not meant for production — the api/Dockerfile handles that separately.

# Keep in sync with api/.ruby-version
ARG RUBY_VERSION=3.2.3
FROM docker.io/library/ruby:${RUBY_VERSION}-slim

# Keep in sync with the Flutter version used to develop app/ (see `flutter --version`)
ARG FLUTTER_VERSION=3.44.4
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=1000

# build-essential: native gem extensions (pg, etc)
# libpq-dev/libyaml-dev/libvips/postgresql-client: Rails (pg, psych, image_processing)
# chromium: headless browser for `flutter run -d chrome` / web debugging — no X server in the
# container, so it's always driven with --headless=new (see .vscode/launch.json).
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev libyaml-dev libvips postgresql-client \
    git curl unzip xz-utils zip ca-certificates sudo \
    chromium \
    chromium-driver \
    chromium-sandbox \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Flutter looks for `google-chrome` by default; point it at the Debian chromium package instead.
ENV CHROME_EXECUTABLE=/usr/bin/chromium

# Chrome's namespace-based sandbox needs SYS_ADMIN, which we don't grant this
# container. Rather than widen the container's capabilities, force
# --no-sandbox for every chromium invocation via Debian's /etc/chromium.d/
# mechanism (the /usr/bin/chromium wrapper sources every file here before
# exec'ing the real binary) — this container never opens untrusted external
# content, it only drives our own local web app for E2E tests, so the
# tradeoff is acceptable here.
RUN echo 'export CHROMIUM_FLAGS="$CHROMIUM_FLAGS --no-sandbox"' > /etc/chromium.d/no-sandbox

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter \
    && chown -R ${USERNAME}:${USERNAME} /opt/flutter \
    && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

USER ${USERNAME}
RUN flutter config --no-analytics --enable-web \
    && flutter precache --web

WORKDIR /workspace
