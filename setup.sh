#!/usr/bin/env bash
set -Eeuo pipefail

readonly GIT_USER_NAME="Jonathan Bergson"
readonly GIT_USER_EMAIL="contato@bergson.me"
readonly DOTFILES_REPOSITORY="https://github.com/jonathanbergson/dotfiles.git"

if [[ -t 1 ]]; then
  readonly GREEN=$'\033[0;32m'
  readonly BLUE=$'\033[1;34m'
  readonly RESET=$'\033[0m'
  readonly INFO_RESET=$'\033[0m'
else
  readonly GREEN=""
  readonly BLUE=""
  readonly RESET=""
  readonly INFO_RESET=""
fi

if [[ -t 2 ]]; then
  readonly RED=$'\033[1;31m'
  readonly YELLOW=$'\033[1;33m'
  readonly ERROR_RESET=$'\033[0m'
  readonly WARNING_RESET=$'\033[0m'
else
  readonly RED=""
  readonly YELLOW=""
  readonly ERROR_RESET=""
  readonly WARNING_RESET=""
fi

DOTFILES_HOME="$HOME/dotfiles"
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [[ -f "$SCRIPT_SOURCE" ]]; then
  SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)"
else
  SCRIPT_DIR="$DOTFILES_HOME"
fi
STEP_COUNTER=0
BREW_BUNDLE_FAILED=0

log_error() {
  printf '\n%sERRO: %s%s\n\n' "$RED" "$*" "$ERROR_RESET" >&2
  exit 1
}

log_warning() {
  printf '\n%sAVISO: %s%s\n\n' "$YELLOW" "$*" "$WARNING_RESET" >&2
}

log_info() {
  printf '\n%s%s%s\n\n' "$BLUE" "$*" "$INFO_RESET"
}

log_step() {
  STEP_COUNTER=$((STEP_COUNTER + 1))
  echo ""
  echo "${GREEN}Step ${STEP_COUNTER}: $*${RESET}"
}

usage() {
  printf '\n'
  printf 'Uso: %s [dotfiles]\n' "${0##*/}"
  printf '\n'
  printf '  sem argumento  Executa todas as etapas\n'
  printf '  dotfiles       Cria somente os links dos dotfiles com Stow\n'
}

setup_ssh_key() {
  command -v ssh-keygen >/dev/null 2>&1 || log_error "Comando necessário não encontrado: ssh-keygen"

  local ssh_dir="$HOME/.ssh"
  local ssh_key="$ssh_dir/id_rsa"
  local username
  local os_name
  local weekday_index
  local month_index
  local day
  local year
  local key_comment
  local -a weekday_names=(Domingo Segunda-feira Terça-feira Quarta-feira Quinta-feira Sexta-feira Sábado)
  local -a month_names=(Janeiro Fevereiro Março Abril Maio Junho Julho Agosto Setembro Outubro Novembro Dezembro)

  mkdir -p "$ssh_dir"
  chmod 700 "$ssh_dir"

  username="$(id -un)"
  case "$(uname -s)" in
    Darwin) os_name="macOS" ;;
    Linux) os_name="Linux" ;;
    *) os_name="$(uname -s)" ;;
  esac

  weekday_index="$(date +%w)"
  month_index="$(date +%m)"
  month_index=$((10#$month_index - 1))
  day="$(date +%d)"
  year="$(date +%Y)"
  key_comment="${username}, ${os_name} - ${weekday_names[$weekday_index]}, ${day} ${month_names[$month_index]} ${year}"

  if [[ ! -f "$ssh_key" ]]; then
    [[ -t 0 ]] || log_error "A geração da chave SSH exige um terminal interativo."
    [[ ! -e "$ssh_key.pub" ]] ||
      log_error "$ssh_key.pub existe sem a chave privada correspondente; preserve e verifique os arquivos."

    log_step "Gerando chave SSH"
    ssh-keygen -t rsa -C "$key_comment" -f "$ssh_key"
  fi

  [[ -f "$ssh_key.pub" ]] || log_error "Não foi encontrada a chave pública $ssh_key.pub."
  log_step "Cadastrando chave SSH no GitHub"
  log_info "Adicione esta chave pública à sua conta do GitHub em https://github.com/settings/keys:"
  cat "$ssh_key.pub"
  printf '\n'
  if [[ -t 0 ]]; then
    printf '%sPressione Enter depois de adicionar a chave ao GitHub para continuar.%s ' "$BLUE" "$INFO_RESET"
    read -r
  else
    log_info "Adicione a chave ao GitHub antes de usar autenticação SSH."
  fi
}

setup_git_and_github() {
  log_step "Configurando a identidade global do Git"
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
}

run_as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    log_error "Instale sudo ou execute como root para instalar pacotes do sistema."
  fi
}

clone_dotfiles_repository() {
  command -v git >/dev/null 2>&1 || log_error "git é necessário para clonar o repositório."

  if [[ -d "$DOTFILES_HOME" ]]; then
    [[ -f "$DOTFILES_HOME/setup.sh" ]] ||
      log_error "$DOTFILES_HOME já existe e não parece ser este repositório."
  else
    log_step "Clonando o repositório jonathanbergson/dotfiles"
    git clone "$DOTFILES_REPOSITORY" "$DOTFILES_HOME"
  fi
}

install_linux_zsh() {
  if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root apt-get install -y zsh git curl stow openssh-client
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y zsh git curl stow openssh-clients
  elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -S --needed --noconfirm zsh git curl stow openssh
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive install zsh git curl stow openssh
  else
    log_error "Distribuição Linux não suportada. Instale zsh, git, curl, stow e OpenSSH manualmente."
  fi
}

install_macos_zsh() {
  command -v brew >/dev/null 2>&1 || log_error "Homebrew precisa estar instalado antes do Zsh."
  if ! command -v zsh >/dev/null 2>&1; then
    brew install zsh
  fi
}

install_macos_homebrew_and_brewfile() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0

  log_step "Instalando Homebrew no macOS"
  if ! command -v brew >/dev/null 2>&1; then
    command -v curl >/dev/null 2>&1 || log_error "curl é necessário para instalar o Homebrew."
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  command -v brew >/dev/null 2>&1 || log_error "Homebrew foi instalado, mas brew não está no PATH."
  log_step "Instalando pacotes do Brewfile no macOS"
  if ! brew bundle --file="$SCRIPT_DIR/apps/homebrew/Brewfile"; then
    BREW_BUNDLE_FAILED=1
    log_warning "Falha ao instalar um ou mais pacotes do Brewfile; continuando as demais etapas."
  fi
}

install_zsh() {
  log_step "Instalando Zsh conforme o sistema operacional"

  case "$(uname -s)" in
    Darwin)
      install_macos_zsh
      ;;
    Linux)
      install_linux_zsh
      ;;
    *)
      log_error "Sistema operacional não suportado: $(uname -s)"
      ;;
  esac
}

install_oh_my_zsh_and_plugins() {
  log_step "Instalando ou verificando Oh My Zsh"
  command -v curl >/dev/null 2>&1 || log_error "Comando necessário não encontrado: curl"
  command -v zsh >/dev/null 2>&1 || log_error "Comando necessário não encontrado: zsh"

  export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
  if [[ ! -d "$ZSH" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  log_step "Clonando Powerlevel10k e plugins do Zsh"
  local zsh_custom="${ZSH_CUSTOM:-$ZSH/custom}"
  mkdir -p "$zsh_custom/themes" "$zsh_custom/plugins"

  if [[ ! -d "$zsh_custom/themes/powerlevel10k" ]]; then
    git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "$zsh_custom/themes/powerlevel10k"
  fi

  if [[ ! -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
    git clone --depth=1 "https://github.com/zsh-users/zsh-autosuggestions.git" "$zsh_custom/plugins/zsh-autosuggestions"
  fi

  if [[ ! -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth=1 "https://github.com/zsh-users/zsh-syntax-highlighting.git" "$zsh_custom/plugins/zsh-syntax-highlighting"
  fi
}

create_zshrc_local() {
  log_step "Criando ~/.zshrc.local"

  if [[ ! -e "$HOME/.zshrc.local" ]]; then
    touch "$HOME/.zshrc.local"
  fi
}

stow_dotfiles() {
  log_step "Criando links dos dotfiles com Stow"
  command -v stow >/dev/null 2>&1 || log_error "Comando necessário não encontrado: stow"

  cd "$SCRIPT_DIR"
  for package_path in */; do
    [[ -d "$package_path" ]] || continue
    local package="${package_path%/}"
    stow --target="$HOME" "$package" ||
      log_error "Falha ao criar links do pacote '$package'; verifique conflitos no diretório home."
  done
}

setup_all() {
  setup_ssh_key
  setup_git_and_github
  clone_dotfiles_repository
  stow_dotfiles
  install_macos_homebrew_and_brewfile
  install_zsh
  install_oh_my_zsh_and_plugins
  create_zshrc_local
  log_info "Setup concluído. Abra um novo terminal para carregar as configurações do Zsh."
}

setup_dotfiles() {
  stow_dotfiles
  log_info "Links dos dotfiles criados com Stow."
}

main() {
  case "${1:-}" in
    "")
      setup_all
      ;;
    dotfiles)
      [[ $# -eq 1 ]] || {
        usage >&2
        return 2
      }
      setup_dotfiles
      ;;
    *)
      usage >&2
      return 2
      ;;
  esac
}

main "$@"
