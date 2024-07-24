#!/bin/sh

# Variables
AUTO_UPDATE=${AUTO_UPDATE:-false}
PHP_EXTENSIONS=${PHP_EXTENSIONS:-}
ADDITIONAL_PACKAGES=${ADDITIONAL_PACKAGES:-}
TIMEZONE=${TIMEZONE:-}

# Functions
update_packages() {
    echo "Updating packages..."
    if apk update > /dev/null 2>&1 && apk upgrade > /dev/null 2>&1; then
        echo "Packages updated successfully."
    else
        echo "Failed to update packages."
        exit 1
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

# Function to install additional packages
install_packages() {
    echo "Installing packages..."
    additional_packages=$(echo "${ADDITIONAL_PACKAGES}" | tr '[:upper:]' '[:lower:]')

    for package in ${additional_packages}; do
        if echo "$package" | grep -qE '^php[0-9]+|^php-'; then
            echo "Use the PHP_EXTENSIONS variable to install PHP extensions."
        else
            apk add --no-cache "$package" > /dev/null 2>&1 | echo "Failed to install package: $package." && exit 1
        fi
    done

    # Clean cache
    rm -rf /var/cache/apk/*
    echo "Packages installed successfully."
}

# Function to set the timezone
set_timezone() {
    echo "Setting timezone to $TIMEZONE"
    # Check if the timezone is valid
    if [ -f "/usr/share/zoneinfo/$TIMEZONE" ]; then
        cp "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime || { echo "Failed to set timezone"; exit 1;}
        echo "$TIMEZONE" > /etc/timezone || { echo "Failed to set timezone"; exit 1;}
    else
        echo "Timezone '$TIMEZONE' is not valid"
        exit 1
    fi
}


# Main
if [ $AUTO_UPDATE ]; then
    update_packages
fi

if [ -n "$PHP_EXTENSIONS" ]; then
    install_php_extensions
fi

if [ -n "$ADDITIONAL_PACKAGES" ]; then
    install_packages
fi

if [ -n "$TIMEZONE" ]; then
    set_timezone
fi

exec php-fpm -F