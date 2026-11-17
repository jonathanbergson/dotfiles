# Dotfiles

## Setup

Clone este repositório para `~/dotfiles` e execute:

```sh
cd ~/dotfiles
bash setup.sh
```

O script configura a chave SSH e o Git, instala Zsh, Oh My Zsh, Powerlevel10k e
plugins, e cria os links dos dotfiles com Stow. Ele mostra a chave pública e
aguarda você adicioná-la manualmente à sua conta do GitHub.

No macOS, também instala o Homebrew e executa o Brewfile em
`apps/homebrew/Brewfile`. No Linux, instala apenas os pré-requisitos do setup
(`zsh`, `git`, `curl` e `stow`) usando `apt`, `dnf`, `pacman` ou `zypper`.
O Brewfile inclui o utilitário `mas`, mas ainda não declara aplicativos da App
Store para instalar.

Se já houver um `~/.zshrc` que não seja um link simbólico para este repositório,
integre ou faça backup dele antes: o script não o sobrescreve.

###### Based on:

- [caiodelgadonew](https://github.com/caiodelgadonew/dotfiles)
- [josean-dev](https://github.com/josean-dev/dev-environment-files)
