#!/usr/bin/env bash
set -Eeuo pipefail

readonly GIT_USER_NAME="Jonathan Bergson"
readonly GIT_USER_EMAIL="contato@bergson.me"
readonly DOTFILES_REPOSITORY="https://github.com/jonathanbergson/dotfiles.git"

if [[ -t 1 ]]; then
  readonly GREEN=$'\033[0;32m'
  readonly RESET=$'\033[0m'
else
  readonly GREEN=""
  readonly RESET=""
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$HOME/dotfiles"

STEP_COUNTER=0
step() {
  STEP_COUNTER=$((STEP_COUNTER + 1))
  echo ""
  echo "${GREEN} >> Step ${STEP_COUNTER}: $*${RESET}"
}

die() {
  printf 'Erro: %s\n' "$*" >&2
  exit 1
}

run_as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    die "Instale sudo ou execute como root para instalar pacotes do sistema."
  fi
}

install_linux_prerequisites() {
  step "Instalando pré-requisitos no Linux"
  if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root apt-get install -y zsh git curl stow
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y zsh git curl stow
  elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -S --needed --noconfirm zsh git curl stow
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive install zsh git curl stow
  else
    die "Distribuição Linux não suportada. Instale zsh, git, curl e stow manualmente."
  fi
}

install_macos_dependencies() {
  step "Instalando ou verificando o Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    command -v curl >/dev/null 2>&1 || die "curl é necessário para instalar o Homebrew."
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  command -v brew >/dev/null 2>&1 || die "Homebrew foi instalado, mas brew não está no PATH."
  step "Instalando dependências do macOS pelo Brewfile e garantindo o Zsh"
  brew bundle --file="$SCRIPT_DIR/apps/homebrew/Brewfile"

  if ! command -v zsh >/dev/null 2>&1; then
    brew install zsh
  fi
}

install_zsh_plugin() {
  local repository="$1"
  local destination="$2"

  if [[ ! -d "$destination" ]]; then
    git clone --depth=1 "$repository" "$destination"
  fi
}

step "Verificando ou clonando o repositório dotfiles"
if [[ "$SCRIPT_DIR" != "$DOTFILES_DIR" ]]; then
  command -v git >/dev/null 2>&1 || die "git é necessário para clonar o repositório."
  if [[ -d "$DOTFILES_DIR" ]]; then
    [[ -f "$DOTFILES_DIR/setup.sh" ]] ||
      die "$DOTFILES_DIR já existe e não parece ser este repositório."
  else
    git clone "$DOTFILES_REPOSITORY" "$DOTFILES_DIR"
  fi
  exec "$DOTFILES_DIR/setup.sh" "$@"
fi

case "$(uname -s)" in
  Darwin)
    install_macos_dependencies
    ;;
  Linux)
    install_linux_prerequisites
    ;;
  *)
    die "Sistema operacional não suportado: $(uname -s)"
    ;;
esac

step "Gerando ou verificando a chave SSH e cadastrando-a no GitHub"
for command_name in git curl stow zsh ssh-keygen; do
  command -v "$command_name" >/dev/null 2>&1 ||
    die "Comando necessário não encontrado: $command_name"
done

ssh_dir="$HOME/.ssh"
ssh_key="$ssh_dir/id_ed25519"
mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

if [[ ! -f "$ssh_key" ]]; then
  [[ -t 0 ]] || die "A geração da chave SSH exige um terminal interativo."
  [[ ! -e "$ssh_key.pub" ]] ||
    die "$ssh_key.pub existe sem a chave privada correspondente; preserve e verifique os arquivos."
  ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "$ssh_key"
fi

[[ -f "$ssh_key.pub" ]] || die "Não foi encontrada a chave pública $ssh_key.pub."
printf '\nAdicione esta chave pública à sua conta do GitHub em https://github.com/settings/keys:\n\n'
cat "$ssh_key.pub"
printf '\n'
if [[ -t 0 ]]; then
  read -r -p "Pressione Enter depois de adicionar a chave ao GitHub para continuar. "
else
  printf 'Adicione a chave ao GitHub antes de usar autenticação SSH.\n'
fi

step "Configurando a identidade global do Git"
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

step "Instalando ou verificando o Oh My Zsh"
export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [[ ! -d "$ZSH" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

step "Instalando Powerlevel10k e plugins do Zsh"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
mkdir -p "$ZSH_CUSTOM/themes" "$ZSH_CUSTOM/plugins"
install_zsh_plugin \
  "https://github.com/romkatv/powerlevel10k.git" \
  "$ZSH_CUSTOM/themes/powerlevel10k"
install_zsh_plugin \
  "https://github.com/zsh-users/zsh-autosuggestions.git" \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
install_zsh_plugin \
  "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

step "Verificando conflitos e criando links dos dotfiles com Stow"
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" && -e "$DOTFILES_DIR/home/.zshrc" ]]; then
  die "Há um ~/.zshrc existente. Faça backup ou integre-o a home/.zshrc no repositório antes de executar novamente."
fi

cd "$DOTFILES_DIR"
for package_path in */; do
  [[ -d "$package_path" ]] || continue
  package="${package_path%/}"
  stow --target="$HOME" "$package" ||
    die "Falha ao criar links do pacote '$package'; verifique conflitos no diretório home."
done

printf '\nSetup concluído. Abra um novo terminal para carregar as configurações do Zsh.\n'
