# Dotfiles

## Setup

Clone este repositório para `~/dotfiles`. Para executar todas as etapas:

```sh
cd ~/dotfiles
./setup.sh
```

Também é possível baixar o script do GitHub e executá-lo diretamente. Ele
clonará o repositório para `~/dotfiles`:

```sh
curl -fsSL https://raw.githubusercontent.com/jonathanbergson/dotfiles/main/setup.sh | bash
```

Esse comando requer `bash`, `curl`, `git` e `ssh-keygen` já disponíveis no
sistema.

Para criar somente os links dos dotfiles no diretório home com Stow:

```sh
./setup.sh dotfiles
```

O script configura a chave SSH e o Git, instala Zsh, Oh My Zsh, Powerlevel10k e
plugins, cria `~/.zshrc.local` se ele ainda não existir e cria os links dos
dotfiles com Stow. Ele mostra a chave pública e aguarda você adicioná-la
manualmente à sua conta do GitHub.

No macOS, também instala o Homebrew e executa o Brewfile em
`apps/homebrew/Brewfile`. No Linux, instala apenas os pré-requisitos do setup
(`zsh`, `git`, `curl`, `stow` e OpenSSH) usando `apt`, `dnf`, `pacman` ou
`zypper`.
O Brewfile inclui o utilitário `mas`, mas ainda não declara aplicativos da App
Store para instalar.

Se já houver um `~/.zshrc` que não seja um link simbólico para este repositório,
integre ou faça backup dele antes: o script não o sobrescreve.

###### Based on:

- [caiodelgadonew](https://github.com/caiodelgadonew/dotfiles)
- [josean-dev](https://github.com/josean-dev/dev-environment-files)
