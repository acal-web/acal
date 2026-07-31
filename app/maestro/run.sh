#!/usr/bin/env bash
# Runs the Maestro E2E suite against a real Rails API (RAILS_ENV=test) + real
# Postgres DB and a real Flutter web build. Used identically in the
# devcontainer and in CI (.github/workflows/e2e.yml) — this script is the
# single source of truth for how the stack is stood up, so both environments
# behave the same way.
#
# Each flow file runs in its own `maestro test` invocation so the test DB can
# be truncated between flows (see reset_db) — this keeps every flow isolated
# regardless of run order or prior failures, which matters once there are
# hundreds of flows: the addresses list has no search field and paginates at
# 10/page, so leftover rows from one flow can push another flow's row off
# screen. This design is serial; parallelizing across Maestro shards would
# need a DB per shard (à la the `parallel_tests` gem convention) — not needed
# yet for this suite's size.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
API_PORT="${API_PORT:-3000}"
WEB_PORT=8080 # must match the `url:` in maestro/flows/*.yaml — Maestro doesn't interpolate env vars there
RAILS_ENV="${RAILS_ENV:-test}"
REPORT_DIR="$REPO_ROOT/app/maestro/report"

mkdir -p "$REPORT_DIR"
rm -f "$REPORT_DIR"/*.xml

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

reset_db() {
  curl -sf -X POST "http://localhost:$API_PORT/test/reset" -o /dev/null
}

echo "== Preparing test database (RAILS_ENV=test) =="
(cd "$REPO_ROOT/api" && RAILS_ENV=test bin/rails db:test:prepare)

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

echo "== Running Maestro flows =="
mapfile -t FLOWS < <(find "$REPO_ROOT/app/maestro/flows" -type f -name '*.yaml' | sort)

set +e
OVERALL_EXIT=0
for flow in "${FLOWS[@]}"; do
  name="$(basename "${flow%.yaml}")"

  echo "== Resetting test DB before $name =="
  reset_db

  echo "== Running $flow =="
  maestro test --headless --format junit --output "$REPORT_DIR/${name}.xml" "$flow"
  [ $? -ne 0 ] && OVERALL_EXIT=1
done
set -e

exit "$OVERALL_EXIT"
