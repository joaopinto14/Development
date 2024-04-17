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
  ### Check if the repository is private or public ###
  # Check if the environment variables GITHUB_USERNAME and GITHUB_TOKEN are set
  if [ -n "${GITHUB_USERNAME}" ] && [ -n "${GITHUB_TOKEN}" ]; then
    # Make a request to the GitHub API using the authentication token
    response=$(curl -sf -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${GITHUB_REPO}")
    # Check if the response contains the error message "Bad credentials"
    if echo "${response}" | grep -q "\"message\": \"Bad credentials\""; then
      # If the error message is present, print an error message and terminate the script
      echo "Bad credentials, please check the GITHUB_USERNAME and GITHUB_TOKEN environment variables."
      exit 1
    fi
    # If authentication is successful, set the repository URL using the username and token
    repo_url="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
  else
    # If the environment variables GITHUB_USERNAME and GITHUB_TOKEN are not set, make a request to the GitHub API without authentication
    response=$(curl -sf "https://api.github.com/repos/${GITHUB_REPO}")
    # Check if the response contains the error message "Not Found"
    if echo "${response}" | grep -q "\"message\": \"Not Found\""; then
      # If the error message is present, print an error message and terminate the script
      echo "ERROR: The repository ${GITHUB_REPO} is private. Please set the GITHUB_USERNAME and GITHUB_TOKEN environment variables."
      exit 1
    fi
    # If the request is successful, set the repository URL without authentication
    repo_url="https://github.com/${GITHUB_REPO}.git"
  fi

  ### Clone the repository ###
  # Build the git clone command
  if [ -n "${GITHUB_BRANCH_TAG}" ]; then
    git_clone_cmd="git clone -q -b ${GITHUB_BRANCH_TAG} ${repo_url} ."
  else
    git_clone_cmd="git clone -q ${repo_url} ."
  fi

  # Execute the git clone command
  ${git_clone_cmd}

  # Check the exit status of the git clone command
  if [ $? -eq 0 ]; then
    echo "Clone executed successfully."
  else
    echo "Clone failed."
    exit 1
  fi
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
    clone_repo
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