FROM ubuntu:16.04
LABEL mantainer="info@kuralabs.io"

# Options
ENV AKAUNTING_VERSION 1.1.6


# -----

USER root
ENV DEBIAN_FRONTEND noninteractive

# Set the locale
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        locales \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8


# Install base Software
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        curl unzip \
        software-properties-common \
        apt-transport-https


# Install supervisord
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        supervisor dirmngr
COPY supervisord/*.conf /etc/supervisor/conf.d/


# Install MySQL
RUN echo 'mysql-server-5.7 mysql-server/root_password_again password defaultrootpwd' | debconf-set-selections \
    && echo 'mysql-server-5.7 mysql-server/root_password password defaultrootpwd' | debconf-set-selections \
    && apt-get install --yes --no-install-recommends \
        mysql-server-5.7 \
    && mkdir -p /var/lib/mysql /var/run/mysqld /var/mysqld/ \
    && chown mysql:mysql /var/lib/mysql /var/run/mysqld /var/mysqld/


# Install NGINX and PHP
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        nginx \
        php7.0-fpm \
        php7.0-mbstring php7.0-xml php7.0-gd
#    && rm /etc/nginx/sites-available/default \

# ADD nginx/akaunting /etc/nginx/sites-available/akaunting
# ADD nginx/nginx.conf /etc/nginx/nginx.conf
# ADD php/php.ini /etc/php/7.0/fpm/php.ini


# Install composer
# Thanks https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
RUN mkdir /opt/composer \
    && curl --silent --show-error -o composer-setup.php https://getcomposer.org/installer \
    && EXPECTED_SIGNATURE=$(curl --silent --show-error https://composer.github.io/installer.sig) \
    && ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');") \
    && if [ "${EXPECTED_SIGNATURE}" != "${ACTUAL_SIGNATURE}" ]; then \
            >&2 echo 'ERROR: Invalid composer installer signature' \
            && rm composer-setup.php \
            && exit 1 \
       ; fi \
    && php composer-setup.php --install-dir=/opt/composer \
    && rm composer-setup.php


# Create system user
RUN adduser \
        --system \
        --home /var/www/akaunting \
        --disabled-password \
        --group \
        akaunting


# Install Akaunting
USER akaunting
WORKDIR /tmp/
RUN curl \
        --location \
        -o akaunting.zip \
        https://github.com/akaunting/akaunting/archive/${AKAUNTING_VERSION}.zip && \
    unzip akaunting.zip && \
    rm akaunting.zip && \
    find akaunting-*/ -mindepth 1 -maxdepth 1 -exec mv -t /var/www/akaunting/ -- {} + && \
    rmdir akaunting-* && \
    ls -lah /var/www/akaunting


# Install dependencies
WORKDIR /var/www/akaunting
RUN php /opt/composer/composer.phar install


# Start supervisord
USER root
EXPOSE 8080

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
