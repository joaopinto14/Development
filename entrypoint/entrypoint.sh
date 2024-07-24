#!/bin/sh

# Variables
AUTO_UPDATE=${AUTO_UPDATE:-false}


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


# Main
if [ $AUTO_UPDATE ]; then
    update_packages
fi

exec php-fpm -F