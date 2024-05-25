#!/bin/ash

# Define default values for environment variables if they are not set
PHP_EXTENSIONS=${PHP_EXTENSIONS:-}

GITHUB_REPO=${GITHUB_REPO:-}
GITHUB_USERNAME=${GITHUB_USERNAME:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}
GITHUB_BRANCH_TAG=${GITHUB_BRANCH_TAG:-}
GITHUB_UPDATE_AUTO=${GITHUB_UPDATE_AUTO:-false}

COMPOSER_INSTALL=${COMPOSER_INSTALL:-false}
NPM_INSTALL=${NPM_INSTALL:-false}

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

# Check if the COMPOSER_INSTALL environment variable is set
if [ "${COMPOSER_INSTALL}" = "true" ]; then
  # Check if the composer.json file exists
  if [ -f /var/www/html/composer.json ]; then
    echo "Installing Composer dependencies..."
    if composer install --no-dev --no-interaction --no-progress --no-suggest; then
      echo "Composer dependencies installed successfully."
    else
      echo "Failed to install Composer dependencies."
      exit 1
    fi
  else
    echo "The 'composer.json' file was not found in the '/var/www/html' directory."
    exit 1
  fi
elif [ "${COMPOSER_INSTALL}" != "false" ]; then
  echo "The COMPOSER_INSTALL environment variable must be set to 'true' or 'false'."
  exit 1
fi

# Check if the NPM_INSTALL environment variable is set
if [ "${NPM_INSTALL}" = "true" ]; then
  # Check if the package.json file exists
  if [ -f /var/www/html/package.json ]; then
    echo "Installing NPM dependencies..."
    if npm install --no-audit --no-fund --no-optional --no-package-lock --no-progress; then
      echo "NPM dependencies installed successfully."
    else
      echo "Failed to install NPM dependencies."
      exit 1
    fi
  else
    echo "The 'package.json' file was not found in the '/var/www/html' directory."
    exit 1
  fi
elif [ "${NPM_INSTALL}" != "false" ]; then
  echo "The NPM_INSTALL environment variable must be set to 'true' or 'false'."
  exit 1
fi

exec php-fpm -F