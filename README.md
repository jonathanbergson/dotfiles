# Dotfiles

1. Gerar chave SSH
1. Login on GitHub e adicionar a chave SSH
1. configurar git
  git config --global user.name "Jonathan Bergson"
  git config --global user.email "contato@bergson.me"
1. Clone this `dotfiles` repository to your home directory
1. Install zsh and oh-my-zsh
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
1. Adicionar tema powerlevel10k e plugins ao oh-my-zsh
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
1. Configurara theme
```sh
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
source ~/.p10k.zsh
```

1. Install Homebrew (https://brew.sh/)
1. Install dependencies with `brew bundle`
1. Install dependencies with mas
1. Run stow to symlink the dotfiles to your home directory with `stow *`

###### Based on:

- [caiodelgadonew](https://github.com/caiodelgadonew/dotfiles)
- [josean-dev](https://github.com/josean-dev/dev-environment-files)
