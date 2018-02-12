#!/usr/bin/env bash

set -o errexit
set -o nounset

sudo mkdir -p /srv/akaunting/mysql
sudo mkdir -p /srv/akaunting/logs
sudo mkdir -p /srv/akaunting/config

docker stop akaunting || true
docker rm akaunting || true

docker run --interactive --tty \
    --hostname akaunting \
    --name akaunting \
    --volume /srv/akaunting/mysql:/var/lib/mysql \
    --volume /srv/akaunting/logs:/var/log \
    --volume /srv/akaunting/config:/var/www/akaunting/config \
    --publish 8080:8080 \
    --env MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
    --env TZ=America/Costa_Rica \
    --volume /etc/timezone:/etc/timezone:ro \
    --volume /etc/localtime:/etc/localtime:ro \
    kuralabs/docker-akaunting:latest bash
