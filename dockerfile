FROM php:7.2-apache-buster

RUN apt-get update && apt-get upgrade -y && apt-get autoremove -y
#RUN apt-get install wget apache2 mariadb-server mariadb-client php7.2 php7.2-fpm php7.2-mysql php7.2-common php7.2-gd php7.2-json php7.2-cli php7.2-curl libapache2-mod-php7.2 php-imagick php-pear php7.2-dev php7.2-mbstring php7.2-xml curl unzip git -y
RUN apt-get install nano wget mariadb-server mariadb-client curl unzip git -y

ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.0/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v3.1.6.0/s6-overlay-aarch64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-aarch64.tar.xz
RUN service apache2 start && service mysql start && service apache2 status && service mysql status && \
    mysql -u root -e "create database nzedb" && \
    mysql -u root -e "grant all privileges on nzedb.* to 'nzedb'@'localhost' identified by 'nzedb'" && \
    mysql -u root -e "grant file on *.* TO 'nzedb'@'localhost'" && \
    mysql -u root -e "flush privileges"


RUN apt-get install apparmor-utils -y && aa-complain /usr/sbin/mysqld; exit 0

RUN apt-get install time p7zip-full mediainfo lame ffmpeg zip unrar-free -y
RUN wget http://launchpadlibrarian.net/339874908/libav-tools_3.3.4-2_all.deb && dpkg -i libav-tools_3.3.4-2_all.deb
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +x /usr/local/bin/composer; exit 0
RUN apt-get install libevent-dev build-essential git autotools-dev automake pkg-config ncurses-dev python python-setuptools python-dev build-essential python-pip ca-certificates -y
RUN apt-get remove tmux -y
RUN git clone https://github.com/tmux/tmux.git --branch 2.0 --single-branch && \
    cd tmux && \
    ./autogen.sh && \
    ./configure && \
    make -j4 && \
    make clean
RUN mkdir /var/www/nZEDb/ && \
    cd /var/www/ && \
    git clone https://github.com/nZEDb/nZEDb.git
RUN cd /var/www/nZEDb/ && su www-data composer install
RUN mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql
RUN mkdir -p /var/www/nZEDb/resources/tmp/unrar 
RUN chmod -R 777 /var/www/nZEDb/ && chown -R www-data:www-data /var/www/nZEDb/ && chmod -R 777 /var/lib/php/sessions
COPY nzedb.conf /etc/apache2/sites-available/nzedb.conf
RUN a2dissite 000-default && a2ensite nzedb.conf && a2enmod rewrite && systemctl restart apache2
VOLUME /var/www/nZEDb
RUN rm -rf /tmp/*
WORKDIR /var/www/nZEDb
ENTRYPOINT [ "/init" ]
