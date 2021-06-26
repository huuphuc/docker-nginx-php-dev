#!/bin/bash

VERSION="2.0.0"

docker build -t php-dev . && \
docker tag php-dev huuphuc/php-dev:${VERSION} && \
docker tag php-dev huuphuc/php-dev:latest && \
docker push huuphuc/php-dev:${VERSION} && \
docker push huuphuc/php-dev:latest

