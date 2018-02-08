#!/usr/bin/env bash

set -o errexit
set -o nounset

sudo mkdir -p /srv/akaunting/mysql
sudo mkdir -p /srv/akaunting/logs

docker stop akaunting || true
docker rm akaunting || true

docker run --detach --init \
    --hostname akaunting \
    --name akaunting \
    --restart always \
    --publish 8080:8080 \
    --volume /srv/akaunting/mysql:/var/lib/mysql \
    --volume /srv/akaunting/logs:/var/log \
    --env MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
    kuralabs/akaunting:latest
