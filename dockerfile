FROM php:7.2-apache-buster

RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y && apt-get install --assume-yes --no-install-recommends --quiet build-essential libmagickwand-dev nano wget mariadb-server mariadb-client curl unzip git php7.2 apparmor-utils time p7zip-full mediainfo lame ffmpeg zip unrar-free libevent-dev build-essential git autotools-dev automake pkg-config ncurses-dev python python-setuptools python-dev build-essential python-pip ca-certificates -y
RUN pecl install imagick \
    && docker-php-ext-enable imagick \
    && docker-php-ext-install exif \
    && docker-php-ext-install gd \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install sockets \
    && docker-php-ext-install pdo_mysql
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.0/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.0/s6-overlay-aarch64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-aarch64.tar.xz

RUN sed -i 's/max_execution_time = 30/max_execution_time = 300/g' /usr/local/etc/php/php.ini-production \
    && sed -i 's/memory_limit = 128M/memory_limit = 1024M/g' /usr/local/etc/php/php.ini-production \
    && sed -i 's@;date.timezone =@date.timezone = "Europe/Berlin"@g' /usr/local/etc/php/php.ini-production

RUN service apache2 start && service mysql start && service apache2 status && service mysql status && \
    mysql -u root -e "create database nzedb" && \
    mysql -u root -e "grant all privileges on nzedb.* to 'nzedb'@'localhost' identified by 'nzedb'" && \
    mysql -u root -e "grant file on *.* TO 'nzedb'@'localhost'" && \
    mysql -u root -e "flush privileges"


RUN aa-complain /usr/sbin/mysqld; exit 0

RUN wget http://launchpadlibrarian.net/339874908/libav-tools_3.3.4-2_all.deb && dpkg -i libav-tools_3.3.4-2_all.deb
#RUN curl -sS https://getcomposer.org/installer | php && \
#RUN curl -s https://getcomposer.org/installer | php && \
#    mv composer.phar /usr/local/bin/composer && \
#    chmod +x /usr/local/bin/composer; exit 0
COPY --from=composer:1.10.19 /usr/bin/composer /usr/bin/composer
RUN apt-get remove tmux -y
RUN git clone https://github.com/tmux/tmux.git --branch 2.0 --single-branch && \
    cd tmux && \
    ./autogen.sh && \
    ./configure && \
    make -j4 && \
    make clean
RUN mkdir /var/www/nZEDb/ && \
    cd /var/www/ && \
    git clone https://github.com/nZEDb/nZEDb.git \
    && chown -R www-data:www-data /var/www \
    && chmod -R 777 /var/www
RUN cd /var/www/nZEDb/ && su -c "composer install --ignore-platform-reqs" -s /bin/bash www-data
#RUN service mysql start && mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root
RUN mkdir -p /var/www/nZEDb/resources/tmp/unrar 
RUN chmod -R 777 /var/www/nZEDb/ && chown -R www-data:www-data /var/www/nZEDb/ 
# && chmod -R 777 /var/lib/php/sessions
COPY nzedb.conf /etc/apache2/sites-available/nzedb.conf
RUN a2dissite 000-default \
    && a2ensite nzedb.conf \
    && a2enmod rewrite \
    && service apache2 restart

VOLUME /var/www/nZEDb
VOLUME /var/lib/mysql

RUN rm -rf /tmp/* \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /var/www/nZEDb
ENTRYPOINT [ "/init" ]
