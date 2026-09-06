#!/usr/bin/env bash
# Runs the integration_test (Patrol) suite against a live Rails test server.
#
# Each test file gets its own `flutter test` invocation on purpose: passing the
# whole directory at once builds fine but fails to launch the app for the
# second and later files ("The log reader stopped unexpectedly, or never
# started"), because a desktop device only gets torn down between separate
# runs.
#
# Usage: app/scripts/run_e2e.sh [extra flutter test args...]
# Env:   E2E_DEVICE (default linux), API_BASE_URL, E2E_ADMIN_USERNAME,
#        E2E_ADMIN_PASSWORD
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DEVICE="${E2E_DEVICE:-linux}"
API_BASE_URL="${API_BASE_URL:-http://localhost:3000}"
E2E_ADMIN_USERNAME="${E2E_ADMIN_USERNAME:-e2e_admin}"
E2E_ADMIN_PASSWORD="${E2E_ADMIN_PASSWORD:-e2e_password123}"

mapfile -t FILES < <(find integration_test -name '*_test.dart' | sort)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "No *_test.dart files under integration_test/" >&2
  exit 1
fi

# Preflight. Without it a missing admin or a dead server shows up as every
# single scenario failing inside setUp, which says nothing about the cause.
echo "== Preflight: $API_BASE_URL =="

if ! curl --fail --silent --show-error --max-time 10 "$API_BASE_URL/up" > /dev/null; then
  echo "API not reachable at $API_BASE_URL/up — is the Rails test server running?" >&2
  exit 1
fi

LOGIN_STATUS=$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 10 \
  -X POST "$API_BASE_URL/session" \
  -H 'Content-Type: application/json' \
  -d "{\"session\":{\"username\":\"$E2E_ADMIN_USERNAME\",\"password\":\"$E2E_ADMIN_PASSWORD\"}}")

if [ "$LOGIN_STATUS" != "201" ]; then
  echo "Cannot log in as '$E2E_ADMIN_USERNAME' (POST /session returned $LOGIN_STATUS)." >&2
  echo "Create the admin with: cd api && RAILS_ENV=test bin/rails users:create_e2e_admin" >&2
  exit 1
fi

echo "== E2E: ${#FILES[@]} file(s) on '$DEVICE' against $API_BASE_URL =="

FAILED=()
for file in "${FILES[@]}"; do
  echo
  echo "== $file =="
  if ! flutter test "$file" -d "$DEVICE" \
    --dart-define=API_BASE_URL="$API_BASE_URL" \
    --dart-define=E2E_ADMIN_USERNAME="$E2E_ADMIN_USERNAME" \
    --dart-define=E2E_ADMIN_PASSWORD="$E2E_ADMIN_PASSWORD" \
    "$@"; then
    FAILED+=("$file")
  fi
done

echo
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "== E2E failed in ${#FAILED[@]} of ${#FILES[@]} file(s) =="
  printf '  %s\n' "${FAILED[@]}"
  exit 1
fi

echo "== E2E passed (${#FILES[@]} file(s)) =="
