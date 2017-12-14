#!/usr/bin/env bash

set -o errexit
set -o nounset

###############
# Supervisord #
###############

# Workaround for issue #72 that makes MySQL to fail to
# start when using docker's overlay2 storage driver:
#   https://github.com/docker/for-linux/issues/72
sudo find /var/lib/mysql -type f -exec touch {} \;

supervisord -c /etc/supervisor/supervisord.conf

###############
# MySQL       #
###############

# Wait for MySQL to start
echo -n "Waiting for MySQL"
for i in {30..0}; do
    if mysqladmin ping >/dev/null 2>&1; then
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

if [ "$i" == 0 ]; then
    echo >&2 'FATAL: MySQL failed to start'
    echo "Showing content of /var/log/mysql/error.log ..."
    cat /var/log/mysql/error.log || true
    exit 1
fi

# Check if password was changed
if echo "SELECT 1" | mysql -u root -pdefaultrootpwd &> /dev/null; then
    echo "Changing root password..."
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; FLUSH PRIVILEGES" | mysql -u root -proot &> /dev/null
else
    echo "Root password already set. Continue..."
fi

# Create database if doesn't exists
if ! echo "USE akaunting"| mysql -u root -p${MYSQL_ROOT_PASSWORD} &> /dev/null; then
    echo "Creating akaunting database..."
    echo "CREATE DATABASE akaunting" | mysql -u root -p${MYSQL_ROOT_PASSWORD} &> /dev/null
else
    echo "Database already exists. Continue..."
fi

# FIXME: Create standard user and grant permissions

# Clear shell history
history -c
history -w

exec "$@"
