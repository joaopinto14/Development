#!/bin/ash

# Define default values for environment variables if they are not set
PHP_EXTENSIONS=${PHP_EXTENSIONS:-}

GITHUB_REPO=${GITHUB_REPO:-}

# Functions

# Function to check and install PHP extensions
check_and_install_extension() {
  installed_extensions=$(php -m | tr '[:upper:]' '[:lower:]')
  extensions_to_install=""

  for extension in ${PHP_EXTENSIONS}; do
    # Convert extension name to lowercase
    extension=$(echo "${extension}" | tr '[:upper:]' '[:lower:]')
    # Check if there is any uninstalled extension
    if ! echo "${installed_extensions}" | grep -wq "${extension}"; then
      extensions_to_install="${extensions_to_install} ${extension}"
    fi
  done

  # Install uninstalled PHP extensions
  if [ -n "${extensions_to_install}" ]; then
    echo "Installing PHP extensions:${extensions_to_install}..."
    for extension in ${extensions_to_install}; do
      apk add -q --no-cache php83-"${extension}" > /dev/null 2>&1
    done
    # Check if extensions were installed successfully
    installed_extensions=$(php -m | tr '[:upper:]' '[:lower:]')
    for extension in ${extensions_to_install}; do
      if ! echo "${installed_extensions}" | grep -wq "${extension}"; then
        echo "Failed to install PHP extension: ${extension}."
        exit 1
      fi
    done
    rm -rf /var/cache/apk/*
    echo "PHP extensions installed successfully."
  fi
}

# Function to clone a git repository
clone_repo() {



}

# Main

# Install the required PHP extensions
if [ -n "${PHP_EXTENSIONS}" ]; then
  check_and_install_extension
fi

# Check if the GITHUB_REPO environment variable is set
if [ -n "${GITHUB_REPO}" ]; then
  # Check if the /var/www/html directory is empty
  if [ ! "$(ls -A . )" ]; then
    echo "Cloning the repository ${GITHUB_REPO}..."
    # TODO Add the command to clone the repository here
    # clone_repo
  else
    # Check if there is a git repository in the /var/www/html directory
    if git -C /var/www/html rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      # Check if the git repository is the same as the one passed as an environment variable
      if [ "$(git -C /var/www/html remote get-url origin | sed -n 's/.*:\/\/github.com\/\([^\/]*\/[^\/]*\)\.git.*/\1/p')" == "${GITHUB_REPO}" ]; then
        # Update the git repository
        echo "Updating the repository ${GITHUB_REPO}..."
        # TODO Add the command to update the repository here
      else
        echo "The '/var/www/html' directory is not empty and contains a different git repository than the one passed as an environment variable."
        exit 1
      fi
    else
      echo "The '/var/www/html' directory is not empty and does not contain a git repository."
      exit 1
    fi
  fi
fi

exec php-fpm -F