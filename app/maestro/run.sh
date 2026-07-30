#!/usr/bin/env bash
# Runs the Maestro E2E suite against a real Rails API + real Postgres DB and a
# real Flutter web build. Used identically in the devcontainer and in CI
# (.github/workflows/e2e.yml) — this script is the single source of truth for
# how the stack is stood up, so both environments behave the same way.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
API_PORT="${API_PORT:-3000}"
WEB_PORT=8080 # must match the `url:` in maestro/flows/*.yaml — Maestro doesn't interpolate env vars there
RAILS_ENV="${RAILS_ENV:-development}"
REPORT_DIR="$REPO_ROOT/app/maestro/report"
TEST_ADDRESS_NAME="Fernando Daltro"

mkdir -p "$REPORT_DIR"

RAILS_PID=""
FLUTTER_PID=""

cleanup() {
  local status=$?
  [ -n "$FLUTTER_PID" ] && kill "$FLUTTER_PID" 2>/dev/null || true
  [ -n "$RAILS_PID" ] && kill "$RAILS_PID" 2>/dev/null || true
  wait 2>/dev/null || true
  exit "$status"
}
trap cleanup EXIT INT TERM

wait_for() {
  local url=$1 label=$2
  echo "Waiting for $label ($url)..."
  timeout 90 bash -c "until curl -sf '$url' -o /dev/null; do sleep 2; done" \
    || { echo "$label never became ready" >&2; exit 1; }
}

clean_test_address() {
  curl -sf "http://localhost:$API_PORT/addresses?size=200" \
    | jq -r --arg name "$TEST_ADDRESS_NAME" '.content[] | select(.name == $name) | .id' \
    | while read -r id; do
        [ -n "$id" ] && curl -sf -X DELETE "http://localhost:$API_PORT/addresses/$id" -o /dev/null
      done
}

echo "== Starting Rails API (RAILS_ENV=$RAILS_ENV) =="
(cd "$REPO_ROOT/api" && RAILS_ENV="$RAILS_ENV" bin/rails server -p "$API_PORT") &
RAILS_PID=$!

echo "== Starting Flutter web (Chrome headless) =="
(cd "$REPO_ROOT/app" && flutter run -d chrome --web-port "$WEB_PORT" \
  --web-browser-flag="--headless=new" \
  --web-browser-flag="--no-sandbox" \
  --web-browser-flag="--disable-web-security" \
  --web-browser-flag="--disable-gpu") &
FLUTTER_PID=$!

wait_for "http://localhost:$API_PORT/addresses" "Rails API"
wait_for "http://localhost:$WEB_PORT/" "Flutter web"

echo "== Pre-clean: removing any leftover '$TEST_ADDRESS_NAME' from a prior run =="
clean_test_address

echo "== Running Maestro flows =="
set +e
maestro test --headless --format junit --output "$REPORT_DIR/junit.xml" \
  "$REPO_ROOT/app/maestro/flows/address/create.yaml"
MAESTRO_EXIT=$?
set -e

echo "== Post-clean: removing '$TEST_ADDRESS_NAME' created by this run =="
clean_test_address

exit "$MAESTRO_EXIT"
