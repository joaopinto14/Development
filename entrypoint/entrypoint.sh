#!/bin/sh

# Variables
AUTO_UPDATE=${AUTO_UPDATE:-false}
PHP_EXTENSIONS=${PHP_EXTENSIONS:-}

# Functions
update_packages() {
    echo "Updating packages..."
    if apk update > /dev/null 2>&1 && apk upgrade > /dev/null 2>&1; then
        echo "Packages updated successfully."
    else
        echo "Failed to update packages."
        return 1
    fi
}

# Function to install additional PHP extensions
install_php_extensions() {
    echo "Installing PHP extensions..."
    installed_extensions=$(php -m | tr '[:upper:]' '[:lower:]')
    php_extensions=$(echo "${PHP_EXTENSIONS}" | tr '[:upper:]' '[:lower:]')

    # Install PHP extensions
    for extension in ${php_extensions}; do
        if ! echo "${installed_extensions}" | grep -wq "${extension}"; then
            apk add -q --no-cache php83-"${extension}" > /dev/null 2>&1
            if ! php -m | tr '[:upper:]' '[:lower:]' | grep -wq "${extension}"; then
                echo "Failed to install PHP extension: ${extension}."
                exit 1
            fi
        fi
    done

    # Clean cache
    rm -rf /var/cache/apk/*
    echo "PHP extensions installed successfully."
}


# Main
if [ $AUTO_UPDATE ]; then
    update_packages
fi

if [ -n "$PHP_EXTENSIONS" ]; then
    install_php_extensions
fi

exec php-fpm -F