#!/usr/bin/env bash

set -o errexit
set -o nounset

sudo mkdir -p /srv/akaunting/mysql
sudo mkdir -p /srv/akaunting/logs

docker stop akaunting || true
docker rm akaunting || true

docker run --interactive --tty \
    --hostname akaunting \
    --name akaunting \
    --volume /srv/akaunting/mysql:/var/lib/mysql \
    --publish 8080:8080 \
    --env MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
    kuralabs/akaunting:latest bash
