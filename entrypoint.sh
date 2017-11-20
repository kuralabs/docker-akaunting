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

exec "$@"
