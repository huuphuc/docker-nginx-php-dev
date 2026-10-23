#!/bin/bash
# Build the image locally for one PHP version and smoke-test it with dgoss (goss.yaml).
# Nothing is pushed; Docker Hub images are published by .github/workflows/publish.yml.
# Usage: ./build.sh [php-version]          e.g. ./build.sh 8.3
#        TEST_ONLY=1 ./build.sh 8.3        test the existing local image without rebuilding
set -euo pipefail

cd "$(dirname "$0")"

LOCAL_IMAGE=php-dev
GOSS_VERSION=v0.4.9
DEFAULT_PHP_VERSION=$(sed -n 's/^ARG PHP_VERSION=//p' Dockerfile)
PHP_VERSION="${1:-${DEFAULT_PHP_VERSION}}"

if [[ ! "${PHP_VERSION}" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "Invalid PHP version '${PHP_VERSION}'. Usage: $0 [php-version], e.g. $0 8.3 (default: ${DEFAULT_PHP_VERSION})" >&2
  exit 1
fi

if [[ "${TEST_ONLY:-0}" != "1" ]]; then
  echo "Building PHP ${PHP_VERSION}..."
  docker build -t "${LOCAL_IMAGE}" --build-arg PHP_VERSION="${PHP_VERSION}" .
fi

# goss runs inside the container, so it must be the Linux binary for the image's architecture.
arch=$(docker image inspect -f '{{.Architecture}}' "${LOCAL_IMAGE}")
goss_dir="${XDG_CACHE_HOME:-${HOME}/.cache}/goss/${GOSS_VERSION}"
goss_bin="${goss_dir}/goss-linux-${arch}"
if [[ ! -x "${goss_bin}" || ! -x "${goss_dir}/dgoss" ]]; then
  echo "Downloading goss ${GOSS_VERSION} (linux-${arch})..."
  mkdir -p "${goss_dir}"
  base="https://github.com/goss-org/goss/releases/download/${GOSS_VERSION}"
  curl -fsSL -o "${goss_bin}" "${base}/goss-linux-${arch}"
  expected=$(curl -fsSL "${base}/goss-linux-${arch}.sha256" | awk '{print $1}')
  actual=$(shasum -a 256 "${goss_bin}" 2>/dev/null || sha256sum "${goss_bin}")
  if [[ "${actual%% *}" != "${expected}" ]]; then
    rm -f "${goss_bin}"
    echo "Checksum mismatch for goss-linux-${arch}; nothing was tested." >&2
    exit 1
  fi
  curl -fsSL -o "${goss_dir}/dgoss" "https://raw.githubusercontent.com/goss-org/goss/${GOSS_VERSION}/extras/dgoss/dgoss"
  chmod +x "${goss_bin}" "${goss_dir}/dgoss"
fi

echo "Testing PHP ${PHP_VERSION}..."
GOSS_PATH="${goss_bin}" GOSS_FILES_PATH=. GOSS_FILES_STRATEGY=cp \
GOSS_OPTS="--retry-timeout 30s --sleep 1s --format documentation --no-color" \
  "${goss_dir}/dgoss" run -e EXPECTED_PHP_VERSION="${PHP_VERSION}" -e PHP_MEMORY_LIMIT=321M "${LOCAL_IMAGE}"

if [[ "${TEST_ONLY:-0}" == "1" ]]; then
  echo "Tested ${LOCAL_IMAGE} (PHP ${PHP_VERSION}). Nothing was pushed."
else
  echo "Built and tested ${LOCAL_IMAGE} (PHP ${PHP_VERSION}). Nothing was pushed."
fi
