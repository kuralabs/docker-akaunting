#!/usr/bin/env bash

set -o errexit
set -o nounset

# Create mount points
sudo mkdir -p /srv/akaunting/mysql
sudo mkdir -p /srv/akaunting/logs
sudo mkdir -p /srv/akaunting/config

# Stop the running container
docker stop akaunting || true

# Remove existing container
docker rm akaunting || true

# Pull the new image
docker pull kuralabs/docker-akaunting:latest

# Run the container
docker run --detach --init \
    --hostname akaunting \
    --name akaunting \
    --restart always \
    --publish 8080:8080 \
    --volume /srv/akaunting/mysql:/var/lib/mysql \
    --volume /srv/akaunting/logs:/var/log \
    --volume /srv/akaunting/config:/var/www/akaunting/config \
    --env MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}" \
    --env TZ=America/Costa_Rica \
    --volume /etc/timezone:/etc/timezone:ro \
    --volume /etc/localtime:/etc/localtime:ro \
    kuralabs/docker-akaunting:latest
