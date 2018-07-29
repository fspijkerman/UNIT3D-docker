FROM alpine:3.8

RUN echo "@community https://nl.alpinelinux.org/alpine/v3.8/community" >> /etc/apk/repositories \
 && apk -U upgrade \
 && apk add \
    git \
    jq \
    dcron \
    rsyslog \
    s6 \
    vim \
    curl \
    zip \
    unzip \
    nodejs \
    npm \
    libpng-dev \
    lcms2-dev \
    bash \
    build-base \
    autoconf \
    su-exec \
    tini@community \
    php7@community \
    php7-phar \
    php7-fpm@community \
    php7-session@community \
    php7-mbstring@community \
    php7-gd@community \
    php7-curl@community \
    php7-zip@community \
    php7-xml@community \
    php7-json@community \
    php7-pdo@community \
    php7-pdo_mysql@community \
    php7-fileinfo@community \
    php7-dom@community \
    php7-tokenizer@community \
    php7-xmlwriter@community \
 && php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
 && cd /tmp \
 && rm -rf /var/cache/apk/*

COPY rootfs /
RUN chmod +x /usr/local/bin/* /services/*/run /services/.s6-svscan/finish

EXPOSE 8888
CMD ["run.sh"]
