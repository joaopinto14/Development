FROM alpine

LABEL maintainer="João Pinto [suport@joaopinto.pt]"

# Install necessary packages
RUN apk update && \
    apk add --no-cache php83 php83-fpm composer nodejs npm github-cli && \
    rm -rf /var/cache/apk/*

# Rename PHP and PHP-FPM binaries
RUN mv /usr/bin/php83 /usr/bin/php && mv /usr/sbin/php-fpm83 /usr/sbin/php-fpm

# Update Composer to use "/usr/bin/php"
RUN sed -i 's|/usr/bin/php83|/usr/bin/php|g' $(which composer)

# Add global git configurations
RUN git config --global --add safe.directory /var/www/html && \
    git config --global --add advice.detachedHead false

# Copy entrypoint script and make it executable
COPY entrypoint/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
CMD ["entrypoint.sh"]