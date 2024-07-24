# ⚙️ *Development*

&nbsp;&nbsp;&nbsp;&nbsp;***Development*** is a compact and efficient *Docker* image, created to make it easier to perform multiple tasks in a web project,
such as environment configurations, installing dependencies or compiling code.

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

## 📝 Issues and Suggestions

&nbsp;&nbsp;&nbsp;&nbsp;If you find any issues related to the image or have suggestions for improvements, do not hesitate to open an
[issue](https://github.com/joaopinto14/Development/issues/new/choose) on *GitHub*. Please provide as many
details as possible to assist in resolving the issue or implementing your suggestion.

## 👥 Contributors

- [João Pinto](https://github.com/joaopinto14) (Developer)

## 🧾️ License

&nbsp;&nbsp;&nbsp;&nbsp;This project is licensed under the *MIT* license - see the [LICENSE.md](LICENSE.md) file for more details.