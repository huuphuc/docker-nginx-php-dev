#!/bin/bash

cd test
docker-compose up -d && sleep 3 && curl -I http://localhost:8088
docker-compose exec php bash -c "php -v"
docker-compose down

