# 🪛  *Development*

&nbsp;&nbsp;&nbsp;&nbsp;Este repositório contém o código fonte da imagem *Docker* ***Development***. Esta imagem
*Docker* foi especificamente projetada para ser de fácil utilização e realizar multiplas tarefas como as de configuração
de ambiente, instalação de dependências, compilação de código ou execução de testes.

## 📖 **Project Description**

&nbsp;&nbsp;&nbsp;&nbsp;A imagem *Docker* ***Development*** foi projetada para ser uma ferramenta para o desenvolvedor e ajudar
na execução de tarefas de configuração de ambiente, instalação de dependências, compilação de código e execução de
testes. 


## 📑 Environment Variables

- **PHP_EXTENSIONS**: The *PHP* extensions to be installed. Default: null (e.g.: pdo_mysql mysqli)


- **TIMEZONE**: The timezone to be used by system. Default: UTC ([List of Timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones))


- **GITHUB_REPO**: The repository to be cloned. Default: null (e.g.: joaopinto14/Development)
- **GITHUB_USERNAME**: The username to be used for *GitHub* authentication. Default: null (e.g.: joaopinto14)
- **GITHUB_TOKEN**: The token to be used for *GitHub* authentication. Default: null
- **GITHUB_BRANCH_TAG**: The branch or tag to be cloned. Default: null (e.g.: main) 
- **GITHUB_UPDATE_AUTO**: The flag to update the repository automatically. Default: false


- **COMPOSER_INSTALL**: The flag to install the dependencies with *Composer*. Default: false


- **NPM_INSTALL**: The flag to install the dependencies with *NPM*. Default: false
- **NPM_COMMAND_TO_BUILD**: The command to build the project with *NPM*. Default: null (e.g.: build)

## ⚒️ **Image Build**

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

## 📝 Issues and Suggestions

&nbsp;&nbsp;&nbsp;&nbsp;If you find any issues related to the image or have suggestions for improvements, do not hesitate to open an
[issue](https://github.com/joaopinto14/Development/issues/new/choose) on *GitHub*. Please provide as many details as
possible to assist in resolving the issue or implementing your suggestion.

## 👥 Contributors

- [João Pinto](https://github.com/joaopinto14) (Developer)
- [Diogo Mendes](https://github.com/DiogoM21) (Ideas and Suggestions)

## 🧾️ License

&nbsp;&nbsp;&nbsp;&nbsp;This project is licensed under the *MIT* license - see the [LICENSE.md](LICENSE.md) file for more details.