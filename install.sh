#!/bin/zsh

set -o errexit
set -o nounset
set -o pipefail

abort() {
  printf "%s\n" "$@" >&2
  exit 1
}

# string formatters
if [[ -t 1 ]]
then
  tty_escape() { printf "\033[%sm" "$1"; }
else
  tty_escape() { :; }
fi
tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

ohai() {
  printf "${tty_blue}==>${tty_bold} %s${tty_reset}\n" "$(shell_join "$@")"
}

warn() {
  printf "${tty_red}Warning${tty_reset}: %s\n" "$(chomp "$1")"
}

readonly HOSTNAME=$(scutil --get LocalHostName)

# Install private SSH keys from GitHub
# mkdir -p ~/.ssh
# curl -s https://raw.githubusercontent.com/iainlowe/laptop/main/ssh/id_rsa > ~/.ssh/id_rsa
# curl -s https://raw.githubusercontent.com/iainlowe/laptop/main/ssh/id_rsa.pub > ~/.ssh/id_rsa.pub
# chmod 600 ~/.ssh/id_rsa
# chmod 644 ~/.ssh/id_rsa.pub

# Install private GPG keys from GitHub
# mkdir -p ~/.gnupg
# curl -s https://raw.githubusercontent.com/iainlowe/laptop/main/gpg/private.key > ~/.gnupg/private.key
# curl -s https://raw.githubusercontent.com/iainlowe/laptop/main/gpg/public.key > ~/.gnupg/public.key
# chmod 600 ~/.gnupg/private.key
# chmod 644 ~/.gnupg/public.key


# whalebrew allows you to package docker commands as local commands

check() {
  which "$@" >/dev/null
}

install_homebrew() {
  check brew && return
  ohai "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

install_rosetta() {
  /usr/bin/pgrep oahd >/dev/null 2>&1 && return

  ohai "Installing Rosetta 2..."
  softwareupdate --install-rosetta --agree-to-license
}

install_xcode_tools() {
  xcode-select -p >/dev/null && return

  ohai "Installing XCode tools..."
  xcode-select --install 2>/dev/null
}

update_xcode_tools() {
  ohai "Updating XCode tools..."
  softwareupdate -ia --agree-to-license
}

install_xcode_tools
install_rosetta
install_homebrew

# Install base Brewfile bundle from GitHub
ohai "Installing Brewfile.base..."
curl -fsSL https://raw.githubusercontent.com/iainlowe/laptop/main/Brewfile.base | brew bundle install -v --file=- 

# Install Brewfile for this host from Github if one exists
if curl --output /dev/null --silent --head --fail "https://raw.githubusercontent.com/iainlowe/laptop/main/Brewfile.${HOSTNAME}"; then
  ohai "Installing Brewfile.${HOSTNAME}..."
  curl -fsSL https://raw.githubusercontent.com/iainlowe/laptop/main/Brewfile.${HOSTNAME} | brew bundle install -v --file=-
else
  warn "No Brewfile.${HOSTNAME} found"
fi

# Install VS Code extensions
: code --list-extensions
: code --install-extension ms-vscode.cpptools
: code --uninstall-extension ms-vscode.csharp