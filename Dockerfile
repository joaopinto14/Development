FROM alpine

LABEL maintainer="João Pinto [suport@joaopinto.pt]"

# Install PHP 8.3 and PHP-FPM 8.3
RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-openssl \
    php83-phar \
    php83-iconv \
    php83-mbstring \
    nodejs \
    npm \
    yarn \
    nano \
    github-cli && \
    rm -rf /var/cache/apk/*

# Install Composer
RUN php83 -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php83 composer-setup.php && \
    php83 -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/bin/composer

# Move PHP and PHP-FPM binaries to the default path
RUN mv /usr/bin/php83 /usr/bin/php && \
    mv /usr/sbin/php-fpm83 /usr/sbin/php-fpm

# Copy custom startup script
COPY entrypoint/entrypoint.sh /usr/local/bin/entrypoint.sh

# Make the startup script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the default directory for the safe command
RUN git config --global --add safe.directory /var/www/html

# Set the default working directory
WORKDIR /var/www/html

CMD ["entrypoint.sh"]