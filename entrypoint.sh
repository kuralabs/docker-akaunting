#!/usr/bin/env bash

set -o errexit
set -o nounset

###############
# Supervisord #
###############

supervisord -c /etc/supervisor/supervisord.conf

###############
# MySQL       #
###############

# echo -n "Waiting for mysqld ..."
# until mysqladmin ping >/dev/null 2>&1; do
#     echo -n "."; sleep 0.2
# done
# echo ""

exec "$@"
