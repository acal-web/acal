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
RUN apt-get update -qq && apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev libyaml-dev libvips postgresql-client \
      git curl unzip xz-utils zip ca-certificates sudo \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

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
