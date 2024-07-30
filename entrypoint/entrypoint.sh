#!/bin/sh

# Variables
AUTO_UPDATE=${AUTO_UPDATE:-false}
PHP_EXTENSIONS=${PHP_EXTENSIONS:-}
ADDITIONAL_PACKAGES=${ADDITIONAL_PACKAGES:-}
TIMEZONE=${TIMEZONE:-}
GITHUB_REPO=${GITHUB_REPO:-}
GITHUB_USERNAME=${GITHUB_USERNAME:-}
GITHUB_TOKEN=${GITHUB_TOKEN:-}
GITHUB_BRANCH_TAG=${GITHUB_BRANCH_TAG:-}
GITHUB_AUTO_UPDATE=${GITHUB_AUTO_UPDATE:-false}


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

# Function to check the repository
github_check_repo() {
    local auth=""
    [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_TOKEN" ] && auth="${GITHUB_USERNAME}:${GITHUB_TOKEN}@"

    response=$(wget -qO- https://${auth}api.github.com/repos/${GITHUB_REPO})
    status=$(echo "$response" | grep -o '"status":[^,]*' | awk -F: '{print $2}' | tr -d ' "')

    if [ "$status" = "404" ]; then
        echo "The repository ${GITHUB_REPO} is private. Please set the GITHUB_USERNAME and GITHUB_TOKEN environment variables."
        exit 1
    fi

    if [ -n "${GITHUB_BRANCH_TAG}" ]; then
        branches=$(wget -qO- https://${auth}api.github.com/repos/${GITHUB_REPO}/branches)
        tags=$(wget -qO- https://${auth}api.github.com/repos/${GITHUB_REPO}/tags)

        if ! echo "$branches" | grep -q "\"name\": \"$GITHUB_BRANCH_TAG\""; then
            if ! echo "$tags" | grep -q "\"name\": \"$GITHUB_BRANCH_TAG\""; then
                echo "The branch/tag ${GITHUB_BRANCH_TAG} does not exist in the repository ${GITHUB_REPO}."
                exit 1
            fi
        fi
    fi
}

# Function to clone the repository
github_clone_repository() {
    echo "Cloning the repository ${GITHUB_REPO}..."

    github_check_repo

    local auth=""
    [ -n "$GITHUB_USERNAME" ] && [ -n "$GITHUB_TOKEN" ] && auth="${GITHUB_USERNAME}:${GITHUB_TOKEN}@"
    local repo_url="https://${auth}github.com/${GITHUB_REPO}.git"

    local git_clone_cmd="git clone -q ${repo_url} ."
    [ -n "${GITHUB_BRANCH_TAG}" ] && git_clone_cmd="git clone -q -b ${GITHUB_BRANCH_TAG} ${repo_url} ."

    if ! ${git_clone_cmd}; then
        echo "Clone failed."
        exit 1
    fi

    echo "Clone executed successfully."
}

# Function to update the repository
github_update_repository() {
    echo "Updating the repository ${GITHUB_REPO}..."

    if ! git fetch --quiet; then
        echo "Failed to fetch the remote references."
        exit 1
    fi

    # Determine if the repository is on a branch or tag
    HEAD_TYPE=$(git symbolic-ref -q --short HEAD || git describe --tags --exact-match HEAD 2>/dev/null)

    if git rev-parse -q --verify "refs/tags/$HEAD_TYPE" >/dev/null; then
        # The repository is on a tag
        echo "The repository is on tag: $HEAD_TYPE"

        # Get the latest tag
        LATEST_TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)")

        # Check if the tag is up to date
        if [ "$HEAD_TYPE" != "$LATEST_TAG" ]; then
            echo "There is a newer tag ($LATEST_TAG) available for the repository."
            # Checkout to the latest tag
            if ! git checkout "$LATEST_TAG" --quiet; then
                echo "Failed to checkout to the latest tag."
                exit 1
            fi
            echo "Repository updated successfully."
        else
            echo "The tag $HEAD_TYPE is up to date."
        fi

    else
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
    fi
}


# Main
if [ $AUTO_UPDATE == "true" ]; then
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

if [ -n "$GITHUB_REPO" ]; then
    if [ ! "$(ls -A .)" ]; then
        github_clone_repository
    elif [ "${GITHUB_UPDATE_AUTO}" = "true" ]; then
        if git -C /var/www/html rev-parse --is-inside-work-tree > /dev/null 2>&1; then
            repo_url=$(git -C /var/www/html remote get-url origin | sed -n 's/.*:\/\/\([^@]*@\)\?github.com\/\([^\/]*\/[^\/]*\)\.git.*/\2/p')
            if [ "$repo_url" = "${GITHUB_REPO}" ]; then
                github_update_repository
            else
                echo "The '/var/www/html' directory contains a different git repository."
                exit 1
            fi
        else
            echo "The '/var/www/html' directory is not a git repository."
            exit 1
        fi
    fi
fi

exec php-fpm -F