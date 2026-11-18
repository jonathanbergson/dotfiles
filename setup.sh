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

if [[ -t 2 ]]; then
  readonly RED=$'\033[1;31m'
  readonly ERROR_RESET=$'\033[0m'
else
  readonly RED=""
  readonly ERROR_RESET=""
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_HOME="$HOME/dotfiles"
STEP_COUNTER=0

die() {
  printf '\n%s >> ERRO: %s%s\n\n' "$RED" "$*" "$ERROR_RESET" >&2
  exit 1
}

step() {
  STEP_COUNTER=$((STEP_COUNTER + 1))
  echo ""
  echo "${GREEN} >> Step ${STEP_COUNTER}: $*${RESET}"
}

usage() {
  printf '\n'
  printf 'Uso: %s [dotfiles]\n' "${0##*/}"
  printf '\n'
  printf '  sem argumento  Executa todas as etapas\n'
  printf '  dotfiles       Cria somente os links dos dotfiles com Stow\n'
}

setup_ssh_key() {
  command -v ssh-keygen >/dev/null 2>&1 || die "Comando necessário não encontrado: ssh-keygen"

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
    [[ -t 0 ]] || die "A geração da chave SSH exige um terminal interativo."
    [[ ! -e "$ssh_key.pub" ]] ||
      die "$ssh_key.pub existe sem a chave privada correspondente; preserve e verifique os arquivos."

    step "Gerando chave SSH"
    ssh-keygen -t rsa -C "$key_comment" -f "$ssh_key"
  fi

  [[ -f "$ssh_key.pub" ]] || die "Não foi encontrada a chave pública $ssh_key.pub."
  step "Cadastrando chave SSH no GitHub"
  printf '\nAdicione esta chave pública à sua conta do GitHub em https://github.com/settings/keys:\n\n'
  cat "$ssh_key.pub"
  printf '\n'
  if [[ -t 0 ]]; then
    read -r -p "Pressione Enter depois de adicionar a chave ao GitHub para continuar. "
  else
    printf 'Adicione a chave ao GitHub antes de usar autenticação SSH.\n'
  fi
}

configure_git() {
  step "Configurando a identidade global do Git"
  git config --global user.name "$GIT_USER_NAME"
  git config --global user.email "$GIT_USER_EMAIL"
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

ensure_dotfiles_repository() {
  command -v git >/dev/null 2>&1 || die "git é necessário para clonar o repositório."

  if [[ -d "$DOTFILES_HOME" ]]; then
    [[ -f "$DOTFILES_HOME/setup.sh" ]] ||
      die "$DOTFILES_HOME já existe e não parece ser este repositório."
  else
    step "Clonando o repositório jonathanbergson/dotfiles"
    git clone "$DOTFILES_REPOSITORY" "$DOTFILES_HOME"
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
  brew bundle --file="$DOTFILES_HOME/apps/homebrew/Brewfile"

  if ! command -v zsh >/dev/null 2>&1; then
    brew install zsh
  fi
}

install_platform_dependencies() {
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
}

install_oh_my_zsh() {
  step "Instalando ou verificando o Oh My Zsh"
  command -v curl >/dev/null 2>&1 || die "Comando necessário não encontrado: curl"
  command -v zsh >/dev/null 2>&1 || die "Comando necessário não encontrado: zsh"

  export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
  if [[ ! -d "$ZSH" ]]; then
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
}

install_zsh_plugin() {
  local repository="$1"
  local destination="$2"

  if [[ ! -d "$destination" ]]; then
    git clone --depth=1 "$repository" "$destination"
  fi
}

install_zsh_plugins() {
  step "Instalando Powerlevel10k e plugins do Zsh"
  local zsh_custom="${ZSH_CUSTOM:-$ZSH/custom}"
  mkdir -p "$zsh_custom/themes" "$zsh_custom/plugins"

  install_zsh_plugin \
    "https://github.com/romkatv/powerlevel10k.git" \
    "$zsh_custom/themes/powerlevel10k"
  install_zsh_plugin \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "$zsh_custom/plugins/zsh-autosuggestions"
  install_zsh_plugin \
    "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
    "$zsh_custom/plugins/zsh-syntax-highlighting"
}

stow_dotfiles() {
  step "Criando links dos dotfiles com Stow"
  command -v stow >/dev/null 2>&1 || die "Comando necessário não encontrado: stow"

  cd "$SCRIPT_DIR"
  for package_path in */; do
    [[ -d "$package_path" ]] || continue
    local package="${package_path%/}"
    stow --target="$HOME" "$package" ||
      die "Falha ao criar links do pacote '$package'; verifique conflitos no diretório home."
  done
}

setup_all() {
  setup_ssh_key
  configure_git
  ensure_dotfiles_repository
  # install_platform_dependencies
  # install_oh_my_zsh
  # install_zsh_plugins
  stow_dotfiles
  printf '\nSetup concluído. Abra um novo terminal para carregar as configurações do Zsh.\n'
}

setup_dotfiles() {
  stow_dotfiles
  printf '\nLinks dos dotfiles criados com Stow.\n'
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
