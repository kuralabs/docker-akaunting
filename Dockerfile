FROM ubuntu:16.04
LABEL mantainer="info@kuralabs.io"

# Options
ENV AKAUNTING_VERSION 1.1.6


# -----

USER root
ENV DEBIAN_FRONTEND noninteractive

# Set the locale
RUN apt-get update && \
    apt-get --yes --no-install-recommends install locales && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8


# Install base Software
RUN apt-get update && apt-get install --yes \
        curl unzip \
        software-properties-common \
        apt-transport-https


# Install supervisord
RUN apt-get update && apt-get --yes install \
        supervisor dirmngr
COPY supervisord/*.conf /etc/supervisor/conf.d/


# Install MySQL
RUN echo 'mysql-server-5.7 mysql-server/root_password_again password defaultrootpwd' | debconf-set-selections && \
    echo 'mysql-server-5.7 mysql-server/root_password password defaultrootpwd' | debconf-set-selections && \
    apt-get update && apt-get install --yes \
        mysql-server-5.7 && \
    mkdir -p /var/lib/mysql /var/run/mysqld /var/mysqld/ && \
    chown mysql:mysql /var/lib/mysql /var/run/mysqld /var/mysqld/


# Install HHVM
ENV HHVM_DISABLE_NUMA true

RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449 && \
    apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xB4112585D386EB94 && \
    add-apt-repository "deb http://dl.hhvm.com/ubuntu xenial main" && \
    apt-get update && \
    apt-get install --yes hhvm
ADD proxygen/server.ini /etc/hhvm/server.ini


# Install composer
RUN mkdir /opt/composer && \
    curl --silent --show-error https://getcomposer.org/installer | hhvm --php -- --install-dir=/opt/composer


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
RUN hhvm /opt/composer/composer.phar install


# Start supervisord
USER root
EXPOSE 8080

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
