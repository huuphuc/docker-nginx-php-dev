#!/bin/bash

cd test
docker-compose up -d && sleep 3 && curl -I http://localhost:8088
docker-compose down

