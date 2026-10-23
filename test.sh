#!/bin/bash
# Smoke test for the locally built "php-dev" image.
# Usage: ./test.sh [expected-php-version]   e.g. ./test.sh 8.3
set -euo pipefail

EXPECTED_PHP_VERSION="${1:-}"
URL=http://localhost:8088

cd "$(dirname "$0")/test"

if docker compose version >/dev/null 2>&1; then
  DC=(docker compose)
else
  DC=(docker-compose)
fi

fail() {
  echo "FAIL: $*" >&2
  "${DC[@]}" logs >&2 || true
  exit 1
}

trap '"${DC[@]}" down >/dev/null 2>&1 || true' EXIT

"${DC[@]}" up -d

echo "Waiting for nginx on ${URL} ..."
for _ in $(seq 1 30); do
  curl -fsS -o /dev/null "${URL}" 2>/dev/null && break
  sleep 1
done

body=$(curl -fsS "${URL}") || fail "${URL} did not return a 2xx response"
[[ "${body}" == "It works! PHP "* ]] || fail "unexpected page body: ${body}"
echo "OK   web: ${body}"

cli_version=$("${DC[@]}" exec -T php php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')
web_version=$(echo "${body}" | sed -E 's/^It works! PHP ([0-9]+\.[0-9]+).*/\1/')
[[ "${cli_version}" == "${web_version}" ]] \
  || fail "CLI runs PHP ${cli_version} but PHP-FPM runs PHP ${web_version}"
if [[ -n "${EXPECTED_PHP_VERSION}" ]]; then
  [[ "${cli_version}" == "${EXPECTED_PHP_VERSION}" ]] \
    || fail "expected PHP ${EXPECTED_PHP_VERSION}, image has PHP ${cli_version}"
fi
echo "OK   cli: PHP ${cli_version}"

[[ $("${DC[@]}" exec -T php php -r 'echo ini_get("display_errors");') == "1" ]] \
  || fail "custom php.ini is not loaded for the CLI"
echo "OK   cli: custom php.ini loaded"

"${DC[@]}" exec -T php composer --version >/dev/null 2>&1 || fail "composer is not runnable"
echo "OK   composer installed"

echo "PASS"
