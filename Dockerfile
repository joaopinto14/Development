FROM alpine

LABEL maintainer="João Pinto [suport@joaopinto.pt]"

# Install necessary packages
RUN apk update && \
    apk add --no-cache php83 php83-fpm php83-openssl php83-phar php83-iconv php83-mbstring nodejs npm && \
    rm -rf /var/cache/apk/*

# Install Composer
RUN php83 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php83 composer-setup.php && \
    php83 -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/bin/composer

# Rename PHP and PHP-FPM binaries
RUN mv /usr/bin/php83 /usr/bin/php && mv /usr/sbin/php-fpm83 /usr/sbin/php-fpm

CMD ["php-fpm", "-F"]