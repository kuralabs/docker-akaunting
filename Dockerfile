FROM ubuntu:16.04
LABEL mantainer="info@kuralabs.io"

# Options
ENV AKAUNTING_VERSION 1.1.10


# -----

USER root
ENV DEBIAN_FRONTEND noninteractive


# Setup and install base system software
RUN echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections \
    && echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections \
    && apt-get update \
    && apt-get --yes --no-install-recommends install \
        locales tzdata sudo \
        ca-certificates apt-transport-https software-properties-common \
        bash-completion iproute2 curl unzip nano tree \
    && rm -rf /var/lib/apt/lists/*
ENV LANG en_US.UTF-8


# Install supervisord
RUN apt-get update \
    && apt-get --yes --no-install-recommends install \
        supervisor dirmngr \
    && rm -rf /var/lib/apt/lists/*


# Install MySQL
ENV MYSQL_DEFAULT_PASSWORD uYqBu/41C4Iog4vq9eShKg==

RUN echo "mysql-server-5.7 mysql-server/root_password_again password ${MYSQL_DEFAULT_PASSWORD}" | debconf-set-selections \
    && echo "mysql-server-5.7 mysql-server/root_password password ${MYSQL_DEFAULT_PASSWORD}" | debconf-set-selections \
    && apt-get update && apt-get install --yes \
        mysql-server-5.7 \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /var/lib/mysql /var/run/mysqld /var/mysqld/ \
    && chown mysql:mysql /var/lib/mysql /var/run/mysqld /var/mysqld/


# Install NGINX and PHP
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        nginx \
        php7.0-fpm \
        php7.0-mbstring php7.0-xml php7.0-gd \
    && rm -rf /var/lib/apt/lists/* \
    && rm /etc/nginx/sites-enabled/default \
    && sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.0/fpm/php.ini \
    && mkdir /run/php


# Install composer
# Thanks https://getcomposer.org/doc/faqs/how-to-install-composer-programmatically.md
RUN curl --silent --show-error -o composer-setup.php https://getcomposer.org/installer \
    && EXPECTED_SIGNATURE=$(curl --silent --show-error https://composer.github.io/installer.sig) \
    && ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');") \
    && if [ "${EXPECTED_SIGNATURE}" != "${ACTUAL_SIGNATURE}" ]; then \
            >&2 echo 'ERROR: Invalid composer installer signature' \
            && rm composer-setup.php \
            && exit 1 \
       ; fi \
    && php composer-setup.php --install-dir=/usr/local/bin/ --filename=composer \
    && rm composer-setup.php


# Install Akaunting
WORKDIR /tmp/
RUN mkdir /var/www/akaunting/ \
    && curl \
        --location \
        -o akaunting.zip \
        https://github.com/akaunting/akaunting/archive/${AKAUNTING_VERSION}.zip \
    && unzip akaunting.zip \
    && rm akaunting.zip \
    && find akaunting-*/ -mindepth 1 -maxdepth 1 -exec mv -t /var/www/akaunting/ -- {} + \
    && rmdir akaunting-*


# Install dependencies
WORKDIR /var/www/akaunting
RUN composer install \
    && chown -R www-data:www-data /var/www/akaunting


# Install files
USER root
COPY supervisord/*.conf /etc/supervisor/conf.d/

COPY nginx/akaunting /etc/nginx/sites-available/akaunting
RUN chown www-data:www-data /etc/nginx/sites-available/akaunting \
    && ln -s /etc/nginx/sites-available/akaunting /etc/nginx/sites-enabled


# Start supervisord
EXPOSE 8080

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
