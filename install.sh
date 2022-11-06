#!/bin/zsh

readonly TAPS=(iainlowe/tap goreleaser/tap 1password/tap)
readonly PKGS=(go goreleaser 1password-cli mas visual-studio-code hub nmap wget)# hazel notion)

# whalebrew allows you to package docker commands as local commands

declare -A APPS

APPS[Kindle]=405399194
APPS["1Password for Safari"]=1569813296
APPS[Ulysses]=1225570693
APPS[Things]=904280696
APPS["Save to Raindrop.io"]=1549370672
APPS["Notion Web Clipper"]=1559269364
APPS[OneTab]=1540160809
APPS[Slack]=803453959

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

ohai "Adding extra taps..."
for tap in ${TAPS}; do
  brew tap ${tap}
done

ohai "Updating brew..."
brew update

ohai "Installing casks/formulae..."
for pkg in ${PKGS}; do
  brew list | grep ${pkg} >/dev/null || brew install ${pkg}
done

ohai "Upgrading existing casks/formulae..."
brew upgrade

ohai "Installing App Store applications..."
for app in ${(k)APPS}; do
    mas install ${APPS[$app]}
done

# Install VS Code extensions
: code --list-extensions
: code --install-extension ms-vscode.cpptools
: code --uninstall-extension ms-vscode.csharp