FROM php:5.6-fpm-alpine

RUN apk update && apk upgrade && \
    apk add --no-cache \
    nginx \
    bash \
    openssh-client \
    wget \
    supervisor \
    curl \
    libcurl \
    g++ \
    python \
    python-dev \
    py-pip \
    augeas-dev \
    libressl-dev \
    ca-certificates \
    dialog \
    autoconf \
    make \
    gcc \
    musl-dev \
    linux-headers \
    libmcrypt-dev \
    libpng-dev \
    icu-dev \
    libpq \
    libxslt-dev \
    libffi-dev \
    freetype-dev \
    sqlite-dev \
    libtool \
    libzip-dev \
    imagemagick-dev \
    libjpeg-turbo-dev \
    php5-apcu && \
    docker-php-ext-configure gd \
      --with-gd \
      --with-freetype-dir=/usr/include/ \
      --with-png-dir=/usr/include/ \
      --with-jpeg-dir=/usr/include/ && \
    pecl install imagick apcu-4.0.11 && \
    docker-php-ext-enable imagick apcu && \
    docker-php-ext-install iconv pdo_mysql pdo_sqlite mysqli gd exif intl xsl json soap dom zip opcache && \
    docker-php-source delete && \
    mkdir -p /run/nginx && \
    apk del gcc musl-dev linux-headers libffi-dev augeas-dev python-dev make autoconf

RUN rm /etc/nginx/nginx.conf

ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/nginx-site.conf /etc/nginx/sites-available/default.conf

RUN mkdir /etc/nginx/sites-enabled && \
    ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

RUN echo "cgi.fix_pathinfo=0" > /usr/local/etc/php/conf.d/docker-vars.ini &&\
    echo "upload_max_filesize = 100M"  >> /usr/local/etc/php/conf.d/docker-vars.ini&&\
    echo "post_max_size = 100M"  >> /usr/local/etc/php/conf.d/docker-vars.ini &&\
    echo "variables_order = \"EGPCS\""  >> /usr/local/etc/php/conf.d/docker-vars.ini && \
    echo "memory_limit = 128M"  >> /usr/local/etc/php/conf.d/docker-vars.ini && \
    sed -i \
        -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" \
        -e "s/pm.max_children = 5/pm.max_children = 4/g" \
        -e "s/pm.start_servers = 2/pm.start_servers = 3/g" \
        -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" \
        -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" \
        -e "s/;pm.max_requests = 500/pm.max_requests = 200/g" \
        -e "s/user = www-data/user = nginx/g" \
        -e "s/group = www-data/group = nginx/g" \
        -e "s/;listen.mode = 0660/listen.mode = 0666/g" \
        -e "s/;listen.owner = www-data/listen.owner = nginx/g" \
        -e "s/;listen.group = www-data/listen.group = nginx/g" \
        -e "s/listen = 127.0.0.1:9000/listen = \/var\/run\/php-fpm.sock/g" \
        -e "s/^;clear_env = no$/clear_env = no/" \
        /usr/local/etc/php-fpm.d/www.conf
#    echo extension=apcu.so > /usr/local/etc/php/conf.d/apcu.ini

ADD conf/supervisord.conf /etc/supervisord.conf
ADD scripts/start.sh /start.sh
ADD src/ /var/www/html/

EXPOSE 80

WORKDIR "/var/www/html"
CMD /bin/sh /start.sh

# ADD zz-docker.conf /usr/local/etc/php-fpm.d/zzz-docker.conf
