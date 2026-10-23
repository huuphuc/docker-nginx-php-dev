#!/bin/bash
# Build and test the image locally for one PHP version. Nothing is pushed;
# Docker Hub images are published by .github/workflows/publish.yml.
# Usage: ./build.sh [php-version]          e.g. ./build.sh 8.3
set -euo pipefail

cd "$(dirname "$0")"

LOCAL_IMAGE=php-dev
DEFAULT_PHP_VERSION=$(sed -n 's/^ARG PHP_VERSION=//p' Dockerfile)
PHP_VERSION="${1:-${DEFAULT_PHP_VERSION}}"

if [[ ! "${PHP_VERSION}" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid PHP version '${PHP_VERSION}'. Usage: $0 [php-version], e.g. $0 8.3 (default: ${DEFAULT_PHP_VERSION})" >&2
  exit 1
fi

echo "Building PHP ${PHP_VERSION}..."
docker build -t "${LOCAL_IMAGE}" --build-arg PHP_VERSION="${PHP_VERSION}" .

echo "Testing PHP ${PHP_VERSION}..."
./test.sh "${PHP_VERSION}"

echo "Built and tested ${LOCAL_IMAGE} (PHP ${PHP_VERSION}). Nothing was pushed."
