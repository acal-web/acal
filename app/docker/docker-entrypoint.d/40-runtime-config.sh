#!/bin/sh
# Regenerates config.js from the real API_BASE_URL env var at container
# start, overwriting the dev-default baked into the image at build time.
# Runs automatically — nginx's own entrypoint executes every *.sh file here
# before starting nginx.
set -eu

cat <<EOF > /usr/share/nginx/html/config.js
window.API_BASE_URL = "${API_BASE_URL:-http://localhost:3000}";
EOF
