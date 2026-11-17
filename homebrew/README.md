# Homebrew — Brewfile

## 1. Gerar o arquivo

No Mac que já possui os pacotes instalados, execute:

```bash
brew bundle dump --force --file=~/dotfiles/homebrew/Brewfile
```

## 2. Validar o arquivo

Para checar se o arquivo é válido, execute:

```bash
brew bundle check --file=~/dotfiles/homebrew/Brewfile
```

## 3. Instalar os pacotes

Para instalar os pacotes no novo Mac, execute:

```bash
brew bundle install --file=~/dotfiles/homebrew/Brewfile
```
