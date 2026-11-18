# Dotfiles

O script configura a chave SSH, Git, instala Zsh, Oh My Zsh, Powerlevel10k e cria os links simbólicos dos
dotfiles com Stow. Ele mostra a chave pública e aguarda você adicioná-la
manualmente à sua conta do GitHub.

## Setup

Execute o seguinte comando para fazer o setup completo do ambiente de desenvolvimento:

```sh
# Executa o script de setup diretamente do repositório
curl -fsSL https://raw.githubusercontent.com/jonathanbergson/dotfiles/main/setup.sh | bash
```

Esse comando requer `bash`, `curl`, `git` e `ssh-keygen` já disponíveis no
sistema.

## Para rodar o script localmente, faça o clone do repositório e execute:

```sh
# Clone o repositório
git clone https://github.com/jonathanbergson/dotfiles.git

# Execute o script de setup localmente
./dotfiles/setup.sh

# Para atualizar apenas os dotfiles, rode:
./dotfiles/setup.sh dotfiles
```

###### Next steps:

- Separar as funções install_homebrew e setup_macos_brewfile, setup_macos_mas
- Exibir mensagem de log_step apenas quando o comando realmente for executado
- Exibir uma log_gray_step para cada comando que não for executado, mas que já esteja instalado
- Adicionar uma função para instalar o mise co nodejs, python, rust
- Criar mensagem se sublog, para quando está instalando os plugins do zsh

###### Based on:

- [caiodelgadonew](https://github.com/caiodelgadonew/dotfiles)
- [josean-dev](https://github.com/josean-dev/dev-environment-files)
