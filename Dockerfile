# Use an official PHP runtime as a base image
FROM php:8.2-apache

RUN apt-get update && \
    apt-get install --yes --force-yes \
    cron vim g++ gettext libicu-dev openssl \
    libc-client-dev libkrb5-dev  \
    libxml2-dev libfreetype6-dev \
    libgd-dev libmcrypt-dev bzip2

RUN apt-get update && \
    apt-get install --yes --force-yes \
    libbz2-dev libtidy-dev libcurl4-openssl-dev \
    libz-dev libmemcached-dev libxslt-dev git-core libpq-dev

RUN apt-get update && \
    apt-get install --yes --force-yes \
    libzip4 libzip-dev libwebp-dev libmagickwand-dev 

RUN apt-get update && \
    apt-get install --yes --force-yes \
    git unzip curl gnupg zlib1g-dev libpng-dev libonig-dev unixodbc-dev

# Microsoft SQL Server Drivers & Tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
RUN apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql18 \
    && ACCEPT_EULA=Y apt-get install -y mssql-tools18 \
    && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc \
    source ~/.bashrc

# PHP Configuration
RUN docker-php-ext-install bcmath bz2 calendar  dba exif gettext iconv intl  soap tidy xsl mbstring zip && \
    docker-php-ext-install mysqli pgsql pdo pdo_mysql pdo_pgsql  && \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \ 
    docker-php-ext-install gd && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install imap && \
    docker-php-ext-configure hash --with-mhash && \
    pecl install xdebug && docker-php-ext-enable xdebug && \
    pecl install mongodb && docker-php-ext-enable mongodb && \
    pecl install redis && docker-php-ext-enable redis && \
    pecl install sqlsrv pdo_sqlsrv && \
    docker-php-ext-enable sqlsrv pdo_sqlsrv && \
    curl -s https://getcomposer.org/installer > composer_installer.php && \
    php composer_installer.php && \
    mv composer.phar /usr/local/bin/composer && \
    rm composer_installer.php

# Apache Configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
    && a2enmod remoteip \
    && a2enmod rewrite \
    && a2enmod headers 

# PHP Configuration File 
COPY php.ini /usr/local/etc/php/

# SSL
COPY 000-default-ssl.conf /etc/apache2/sites-available/000-default-ssl.conf

RUN a2enmod ssl 
RUN a2ensite 000-default-ssl.conf
RUN openssl req -subj '/CN=*.viriyah.co.th/O=The Viriyah Insurance Public Company Limited/C=TH' -new -newkey rsa:2048 -days 365 -nodes -x509 -keyout /etc/ssl/private/ssl-cert-viriyah.key -out /etc/ssl/certs/ssl-cert-viriyah.pem

# Time Zone
ENV TZ=Asia/Bangkok
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata

RUN echo "* * * * * www-data php /var/www/html/cronjob/test.php >> /var/www/html/logs/cronjob/cron.log" >> /etc/crontab

# Change CMD to have cron running
RUN echo "#!/bin/sh\ncron\n/usr/local/bin/apache2-foreground" > /usr/bin/run
RUN chmod u+x /usr/bin/run
CMD ["run"]

EXPOSE 80
EXPOSE 443