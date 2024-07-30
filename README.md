# ⚙️ *Development*

&nbsp;&nbsp;&nbsp;&nbsp;***Development*** is a compact and efficient *Docker* image, created to make it easier to perform
multiple tasks in a web project, such as environment configurations, installing dependencies or compiling code.

## 📖 Project Description

&nbsp;&nbsp;&nbsp;&nbsp;***Development*** is a *Docker* image created using the Linux distribution ***Alpine***. 
Some common packages for web projects, such as PHP, Node.js, NPM, Composer, and Git, have been added to facilitate the 
execution of common tasks. There is the possibility to install additional *PHP* extensions, as well as more packages and
other configurations through the [environment variables](#-environment-variables). Some tasks can also be executed 
automatically, such as package updates, repository cloning, repository updates, dependency installation, and code 
compilation, making the user's work easier.

## ⚒️ Image Build

Follow the steps below to build the *Docker* image:

1. Clone the repository with the command:

```
git clone https://github.com/joaopinto14/Development.git
```

1. Navigate to the project directory with the command:

```
cd Development
```

1. Build the *Docker* image with the command:

```
docker build -t development .
```

## 📑 Environment Variables

- **AUTO_UPDATE**: If set to `true`, the image will automatically update the installed packages. Default: false
- **PHP_EXTENSIONS**: The *PHP* extensions to be installed. Default: null (e.g.: pdo_mysql mysqli)
- **ADDITIONAL_PACKAGES**: Additional packages to be installed. Default: null (e.g.: git zip unzip)
- **TIMEZONE**: The timezone to be used by system. Default: UTC ([List of Timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))
- **GITHUB_REPO**: The repository of the project. Default: null (e.g.: joaopinto14/Development)
- **GITHUB_USERNAME**: The username of the *GitHub* account. Default: null (e.g.: joaopinto14)
- **GITHUB_TOKEN**: The *GitHub* token to access the repository. Default: null 
- **GITHUB_BRANCH_TAG**: The branch or tag of the repository.
- **GITHUB_AUTO_UPDATE**: If set to `true`, the image will automatically update the repository. Default: false
- **COMPOSER_INSTALL**: If set to `true`, the image will install the dependencies using *Composer*. Default: false
- **NPM_INSTALL**: If set to `true`, the image will install the dependencies using *NPM*. Default: false
- **NPM_BUILD**: If set to `true`, the image will compile the code using *NPM*. Default: false

## Usage Example

- Using the command line:
```
docker run -it --rm \
    -e AUTO_UPDATE=true \
    -e PHP_EXTENSIONS=pdo_mysql mysqli \
    -e ADDITIONAL_PACKAGES=git zip unzip \
    -e TIMEZONE=America/Sao_Paulo \
    -e GITHUB_REPO=joaopinto14/Development \
    -e GITHUB_USERNAME=joaopinto14 \
    -e GITHUB_TOKEN=your_token \
    -e GITHUB_BRANCH_TAG=main \
    -e GITHUB_AUTO_UPDATE=true \
    -e COMPOSER_INSTALL=true \
    -e NPM_INSTALL=true \
    -e NPM_BUILD=true \
    development
```

- Using *Docker Compose*:
```
services:
  development:
    image: development
    environment:
      - AUTO_UPDATE=true
      - PHP_EXTENSIONS=pdo_mysql mysqli
      - ADDITIONAL_PACKAGES=git zip unzip
      - TIMEZONE=America/Sao_Paulo
      - GITHUB_REPO=joaopinto14/Development
      - GITHUB_USERNAME=joaopinto14
      - GITHUB_TOKEN=your_token
      - GITHUB_BRANCH_TAG=main
      - GITHUB_AUTO_UPDATE=true
      - COMPOSER_INSTALL=true
      - NPM_INSTALL=true
      - NPM_BUILD=true
```

## 📝 Issues and Suggestions

&nbsp;&nbsp;&nbsp;&nbsp;If you find any issues related to the image or have suggestions for improvements, do not hesitate to open an
[issue](https://github.com/joaopinto14/Development/issues/new/choose) on *GitHub*. Please provide as many
details as possible to assist in resolving the issue or implementing your suggestion.

## 👥 Contributors

- [João Pinto](https://github.com/joaopinto14) (Developer)

## 🧾️ License

&nbsp;&nbsp;&nbsp;&nbsp;This project is licensed under the *MIT* license - see the [LICENSE.md](LICENSE.md) file for more details.