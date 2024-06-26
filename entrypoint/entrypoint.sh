#!/bin/sh

# Variables
TIMEZONE=${TIMEZONE:-}
PHP_EXTENSIONS=${PHP_EXTENSIONS:-}
GITHUB_REPO=${GITHUB_REPO:-}

# Functions

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

# Function to install additional PHP extensions
install_php_extensions() {
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

# Function to clone a git repository
clone_repo() {
    # TODO
}

# Main

if [ -n "$TIMEZONE" ]; then
    set_timezone
fi

if [ -n "$PHP_EXTENSIONS" ]; then
    install_php_extensions
fi

if [ -n "$GITHUB_REPO" ]; then
    clone_repo
fi



#### TODO: Refazer o script mais simples e mais eficiente














GITHUB_USERNAME=${GITHUB_USERNAME:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}
GITHUB_BRANCH_TAG=${GITHUB_BRANCH_TAG:-}
GITHUB_UPDATE_AUTO=${GITHUB_UPDATE_AUTO:-false}

PROJECT_PATH=${PROJECT_PATH:-/var/www/html}

COMPOSER_INSTALL=${COMPOSER_INSTALL:-false}

NPM_INSTALL=${NPM_INSTALL:-false}
NPM_COMMAND_TO_BUILD=${NPM_COMAND_TO_BUILD:-}










# Function to clone a git repository
clone_repo() {
  # Check if the environment variables GITHUB_USERNAME and GITHUB_TOKEN are set
  if [ -n "${GITHUB_USERNAME}" ] && [ -n "${GITHUB_TOKEN}" ]; then
    # Make a request to the GitHub API using the authentication token
    response=$(curl -sf -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${GITHUB_REPO}")
    # Check if the response is empty
    if [ -z "${response}" ]; then
      # If the response is empty, print an error message and terminate the script
      echo "Bad credentials, please check the GITHUB_USERNAME and GITHUB_TOKEN environment variables."
      exit 1
    fi
    # Make a request to the GitHub API to get the branches and tags
    if [ -n "${GITHUB_BRANCH_TAG}" ]; then
      branches=$(curl -sf -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${GITHUB_REPO}/branches" | jq -r '.[].name' | tr '\n' ' ')
      tags=$(curl -sf -H "Authorization: token ${GITHUB_TOKEN}" "https://api.github.com/repos/${GITHUB_REPO}/tags" | jq -r '.[].name' | tr '\n' ' ')
      # Check if the GITHUB_BRANCH_TAG is in the branches or tags
      if ! echo "${branches}" | grep -q "${GITHUB_BRANCH_TAG}" && ! echo "${tags}" | grep -q "${GITHUB_BRANCH_TAG}"; then
        echo "Branch/tag ${GITHUB_BRANCH_TAG} not found in the repository ${GITHUB_REPO}."
        exit 1
      fi
    fi

    # If authentication is successful, set the repository URL using the username and token
    repo_url="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_REPO}.git"
  else
    # If the environment variables GITHUB_USERNAME and GITHUB_TOKEN are not set, make a request to the GitHub API without authentication
    response=$(curl -sf "https://api.github.com/repos/${GITHUB_REPO}")
    # Check if the response is empty
    if [ -z "${response}" ]; then
      # If the response is empty, print an error message and terminate the script
      echo "ERROR: The repository ${GITHUB_REPO} is private. Please set the GITHUB_USERNAME and GITHUB_TOKEN environment variables."
      exit 1
    fi
    # Make a request to the GitHub API to get the branches and tags
    if [ -n "${GITHUB_BRANCH_TAG}" ]; then
      branches=$(curl -sf "https://api.github.com/repos/${GITHUB_REPO}/branches" | jq -r '.[].name' | tr '\n' ' ')
      tags=$(curl -sf "https://api.github.com/repos/${GITHUB_REPO}/tags" | jq -r '.[].name' | tr '\n' ' ')
      # Check if the GITHUB_BRANCH_TAG is in the branches or tags
      if ! echo "${branches}" | grep -q "${GITHUB_BRANCH_TAG}" && ! echo "${tags}" | grep -q "${GITHUB_BRANCH_TAG}"; then
        echo "Branch/tag ${GITHUB_BRANCH_TAG} not found in the repository ${GITHUB_REPO}."
        exit 1
      fi
    fi
    # If the request is successful, set the repository URL without authentication
    repo_url="https://github.com/${GITHUB_REPO}.git"
  fi

  # Check if the GITHUB_BRANCH_TAG environment variable is set
  if [ -n "${GITHUB_BRANCH_TAG}" ]; then
    git_clone_cmd="git clone -q -b ${GITHUB_BRANCH_TAG} ${repo_url} ."
  else
    git_clone_cmd="git clone -q ${repo_url} ."
  fi

  # Execute the git clone command and check the exit status directly
  if ! ${git_clone_cmd}; then
    echo "Clone failed."
    exit 1
  fi
  echo "Clone executed successfully."
}

# Function to update a git repository
update_repo() {
  echo "Checking for updates..."

  # Fetch the remote references
  if ! git fetch --quiet; then
    echo "Failed to fetch the remote references."
    exit 1
  fi

  # Determine if the repository is on a branch or tag
  HEAD_TYPE=$(git rev-parse --abbrev-ref HEAD)

  if [ "$HEAD_TYPE" != "HEAD" ]; then
    # The repository is on a branch
    echo "The repository is on branch: $HEAD_TYPE"

    # Check if the branch is up to date
    UPSTREAM_COMMITS=$(git rev-list --left-right --count origin/"$HEAD_TYPE"...HEAD | awk '{print $1}')
    if [ "$UPSTREAM_COMMITS" -gt 0 ]; then
      echo "There are $UPSTREAM_COMMITS commit(s) to be pulled from the repository."
      # Pull the latest changes
      if ! git pull --quiet; then
        echo "Failed to pull the latest changes."
        exit 1
      fi
      echo "Repository updated successfully."
    else
      echo "The branch $HEAD_TYPE is up to date."
    fi
  else
    # The repository is on a tag
    CURRENT_TAG=$(git describe --tags --exact-match HEAD 2>/dev/null)
    echo "The repository is on tag: $CURRENT_TAG"

    # Get the latest tag
    LATEST_TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)")

    # Check if the tag is up to date
    if [ "$CURRENT_TAG" != "$LATEST_TAG" ]; then
      echo "There is a newer tag ($LATEST_TAG) available for the repository."
      # Checkout to the latest tag
      if ! git checkout "$LATEST_TAG" --quiet; then
        echo "Failed to checkout to the latest tag."
        exit 1
      fi
      echo "Repository updated successfully."
    else
      echo "The tag $CURRENT_TAG is up to date."
    fi
  fi
}

# Function to install Composer dependencies
install_composer_dependencies() {
  if [ -f ./composer.json ]; then
    echo "Installing Composer dependencies..."
    if composer install --no-dev --no-interaction --no-progress > /dev/null 2>&1; then
      echo "Composer dependencies installed successfully."
    else
      echo "Failed to install Composer dependencies."
      exit 1
    fi
  else
    echo "The 'composer.json' file was not found in the '${PROJECT_PATH}' directory."
    exit 1
  fi
}

# Function to install NPM dependencies
install_npm_dependencies() {
  if [ -f ./package.json ]; then
    echo "Installing NPM dependencies..."
    if npm install --no-audit --no-fund --omit=optional --no-package-lock --no-progress > /dev/null 2>&1; then
      echo "NPM dependencies installed successfully."
    else
      echo "Failed to install NPM dependencies."
      exit 1
    fi
  else
    echo "The 'package.json' file was not found in the '${PROJECT_PATH}' directory."
    exit 1
  fi
}

# Function to build the application
build_application() {
  if [ -f ./package.json ]; then
    echo "Building the application..."
    if ! jq -e .scripts[\"${NPM_COMMAND_TO_BUILD}\"] ./package.json > /dev/null 2>&1; then
      echo "The command ${NPM_COMMAND_TO_BUILD} is not defined in the package.json file."
      exit 1
    fi
    npm_command="npm run ${NPM_COMMAND_TO_BUILD}"
    if ${npm_command}; then
      echo "Command '${npm_command}' executed successfully."
    else
      echo "Failed to build the application."
      exit 1
    fi
  else
    echo "The 'package.json' file was not found in the '${PROJECT_PATH}' directory."
    exit 1
  fi
}







________________________________

# Set the timezone
if [ -n "${TIMEZONE}" ]; then
  ln -snf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime || { echo "Failed to set timezone to '${TIMEZONE}'."; exit 1; }
  echo "${TIMEZONE}" > /etc/timezone || { echo "Failed to set timezone to '${TIMEZONE}'."; exit 1; }
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
      if [ "$(git -C /var/www/html remote get-url origin | sed -n 's/.*:\/\/\([^@]*@\)\?github.com\/\([^\/]*\/[^\/]*\)\.git.*/\2/p')" == "${GITHUB_REPO}" ]; then
        if [ "${GITHUB_UPDATE_AUTO}" = "true" ]; then
          update_repo
        elif [ "${GITHUB_UPDATE_AUTO}" != "false" ]; then
          echo "The GITHUB_UPDATE_AUTO environment variable must be set to 'true' or 'false'."
          exit 1
        fi
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

cd $PROJECT_PATH

# Check if the COMPOSER_INSTALL environment variable is set
if [ "${COMPOSER_INSTALL}" = "true" ]; then
  install_composer_dependencies
elif [ "${COMPOSER_INSTALL}" != "false" ]; then
  echo "The COMPOSER_INSTALL environment variable must be set to 'true' or 'false'."
  exit 1
fi

# Check if the NPM_INSTALL environment variable is set
if [ "${NPM_INSTALL}" = "true" ]; then
  install_npm_dependencies
elif [ "${NPM_INSTALL}" != "false" ]; then
  echo "The NPM_INSTALL environment variable must be set to 'true' or 'false'."
  exit 1
fi

# Check if the NPM_COMMAND_TO_BUILD environment variable is set
if [ -n "${NPM_COMMAND_TO_BUILD}" ]; then
  build_application
fi

exec php-fpm -F