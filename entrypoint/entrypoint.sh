#!/bin/ash

# Define default values for environment variables if they are not set
PHP_EXTENSIONS=${PHP_EXTENSIONS:-}

GITHUB_REPO=${GITHUB_REPO:-}

# Functions

# Function to check and install PHP extensions
check_and_install_extension() {
  installed_extensions=$(php -m)
  extensions_to_install=""

  for extension in ${PHP_EXTENSIONS}; do
    # Check if there is any uninstalled extension
    if ! echo "${installed_extensions}" | grep -wq "${extension}"; then
      extensions_to_install="${extensions_to_install} ${extension}"
    fi
  done

  # Install uninstalled PHP extensions
  if [ -n "${extensions_to_install}" ]; then
    echo "Installing PHP extensions: ${extensions_to_install}..."
    for extension in ${extensions_to_install}; do
      apk add -q --no-cache php83-"${extension}" > /dev/null 2>&1
      if ! php -m | grep -wq "${extension}"; then
        echo "Failed to install PHP extension: ${extension}."
        exit 1
      fi
    done
    rm -rf /var/cache/apk/*
    echo "PHP extensions installed successfully."
  fi
}

# Main

# Install the required PHP extensions
if [ -n "${PHP_EXTENSIONS}" ]; then
  check_and_install_extension
fi

if [ -n "${GITHUB_REPO}" ]; then

  # Check if the directory /var/www/html is empty
  if [ ! "$(ls -A . )" ]; then
    echo "Cloning the repository ${GITHUB_REPO}..."
    # git clone the repository
  else
    # Verificar se dentro do diretorio "/var/www/html" existe um repositorio git
    if [ -d ".git" ]; then
      # Verificar se o repositorio git é o mesmo que foi passado como variavel de ambiente
      if [ "$(git -C /var/www/html remote get-url origin)" == "${GITHUB_REPO}" ]; then
        # atualizar o repositorio git
        echo "Atualizando o repositório ${GITHUB_REPO}..."
      else
        echo "O diretório '/var/www/html' não está vazio e contém um repositório git diferente do que foi passado como variável de ambiente."
        exit 1
      fi
    else
      echo "O diretório '/var/www/html' não está vazio e não contém um repositório git."
      exit 1
    fi
  fi

fi

exec php-fpm -F