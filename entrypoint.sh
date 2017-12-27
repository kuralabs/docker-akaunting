#!/usr/bin/env bash

set -o errexit
set -o nounset

MYSQL_ROOT_PASSWORD_SET=${MYSQL_ROOT_PASSWORD:-}

if [ -z "${MYSQL_ROOT_PASSWORD_SET}" ]; then
    echo "Please set the MySQL root password:"
    echo "    docker run -e MYSQL_ROOT_PASSWORD=<mysecret> ... kuralabs/akaunting:latest ..."
    echo "See README.rst for more information on usage."
    exit 1
fi

###############
# Supervisord #
###############

# Workaround for issue #72 that makes MySQL to fail to
# start when using docker's overlay2 storage driver:
#   https://github.com/docker/for-linux/issues/72
find /var/lib/mysql -type f -exec touch {} \;

echo "Starting supervisord ..."
supervisord -c /etc/supervisor/supervisord.conf

###############
# MySQL       #
###############

# Wait for MySQL to start
echo -n "Waiting for MySQL "
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
echo -e "[client]\nuser=root\npassword=defaultrootpwd" > ~/.my.cnf

if echo "SELECT 1;" | mysql &> /dev/null; then
    echo "Changing root password ..."
    echo "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
          FLUSH PRIVILEGES;" | mysql
else
    echo "Root password already set. Continue ..."
fi


# Create database if doesn't exists
echo -e "[client]\nuser=root\npassword=${MYSQL_ROOT_PASSWORD}" > ~/.my.cnf

if ! echo "USE akaunting;" | mysql &> /dev/null; then
    echo "Creating akaunting database ..."
    echo "CREATE DATABASE akaunting;" | mysql
else
    echo "Database already exists. Continue ..."
fi

# Create standard user and grant permissions
if ! echo "SELECT COUNT(*) FROM mysql.user WHERE user = 'akaunting';" | mysql | grep 1 &> /dev/null; then
    echo "Creating akaunting database user ..."

    USER_PASSWORD=$(openssl rand -base64 32)

    echo "CREATE USER 'akaunting'@'localhost' IDENTIFIED BY '${USER_PASSWORD}';
          GRANT ALL PRIVILEGES ON akaunting.* TO 'akaunting'@'localhost';
          FLUSH PRIVILEGES;" | mysql

    echo "*****************************************************************"
    echo "IMPORTANT!! USER 'akaunting' CREATED WITH PASSWORD:"
    echo ""
    echo "${USER_PASSWORD}"
    echo ""
    echo "Use the above credentials to setup your new Akaunting deployment!"
    echo "*****************************************************************"

else
    echo "Akaunting database user already created. Continue ..."
fi

# Remove credentials file
rm ~/.my.cnf

# Clear shell
unset MYSQL_ROOT_PASSWORD
history -c
history -w

exec "$@"
