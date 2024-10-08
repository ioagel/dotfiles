#!/usr/bin/env bash

if [[ "$1" != 'desktop' && "$1" != 'laptop' ]]; then
  echo "This script requires one argument: 'desktop' or 'laptop'"
  exit 1
fi

export PATH="/usr/local/bin:$PATH"

WITH_ASDF_NODE="${WITH_ASDF_NODE:-yes}"
WITH_ASDF_PYTHON="${WITH_ASDF_PYTHON:-yes}"
WITH_ASDF_JAVA="${WITH_ASDF_JAVA:-yes}"
WITH_ASDF_GO="${WITH_ASDF_GO:-yes}"
WITH_ASDF_LAZYDOCKER="${WITH_ASDF_LAZYDOCKER:-yes}"
WITH_ASDF_LAZYGIT="${WITH_ASDF_LAZYGIT:-yes}"
WITH_ASDF_SOPS="${WITH_ASDF_SOPS:-yes}"
WITH_ASDF_STEP="${WITH_ASDF_STEP:-yes}"
WITH_ASDF_STARSHIP="${WITH_ASDF_STARSHIP:-yes}"
WITH_ASDF_K9S="${WITH_ASDF_K9S:-yes}"
WITH_ASDF_K3D="${WITH_ASDF_K3D:-yes}"
KUBECTL_VERSION=1.30.4
WITH_ASDF_KUBECTL="${WITH_ASDF_KUBECTL:-yes}"
WITH_ASDF_ISTIOCTL="${WITH_ASDF_ISTIOCTL:-yes}"
WITH_GUI="${WITH_GUI:-no}" # for Linux

# shellcheck disable=SC2154
trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

OS="$(uname)"
if [[ "$OS" != 'Darwin' && "$OS" != 'Linux' ]]; then
  echo "This script supports only Mac and Linux!"
  exit 1
fi

cwd="$(pwd)"
export cwd

. ./sh_functions

# Authentication
sudo -v
# Keep-alive: update existing `sudo` time stamp until bootstrap has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &

if [ "$OS" = 'Darwin' ]; then
  . ./mac.sh
elif [ "$(lsb_release -is 2>/dev/null)" = 'Ubuntu' ]; then
  # we are definitely in Ubuntu from the check above
  . ./ubuntu.sh
fi

if [ ! -d "$HOME/.asdf" ]; then
  fancy_echo "########## Installing asdf version manager ##########"
  asdf_latest_version=$(latest_release_from_github asdf-vm/asdf)
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch "$asdf_latest_version"
fi

. ../.asdf/asdf.sh

if [ "$WITH_ASDF_NODE" = 'yes' ]; then
  fancy_echo "########## Installing latest Node lts ##########"
  command -v node-versions || sudo npm i -g @darkobits/node-versions
  LATEST_LTS=$(node-versions -o json | jq -r .lts.version.full)
  add_or_update_asdf_plugin nodejs
  install_latest_asdf_language nodejs "$LATEST_LTS"
  asdf global nodejs system
fi

# asdf python 3 setup
if [ "$WITH_ASDF_PYTHON" = 'yes' ]; then
  fancy_echo "########## Installing latest Python 3 ##########"
  add_or_update_asdf_plugin python
  install_latest_asdf_language python
  asdf global python system
fi

# Java setup
if [ "$WITH_ASDF_JAVA" = 'yes' ]; then
  fancy_echo "########## Installing latest Java 8, 17 and 21 lts ##########"
  add_or_update_asdf_plugin java
  install_latest_asdf_language java "$(asdf list-all "java" | grep "temurin-8" | tail -1)"
  install_latest_asdf_language java "$(asdf list-all "java" | grep "temurin-17" | tail -1)"
  install_latest_asdf_language java "$(asdf list-all "java" | grep "temurin-21" | tail -1)"
  asdf global java system
fi

# Golang Setup
if [ "$WITH_ASDF_GO" = 'yes' ]; then
  fancy_echo "########## Installing latest GoLang ##########"
  mkdir -p "$HOME"/.golang/{bin,pkg,src}
  export GOPATH="$HOME/.golang"

  add_or_update_asdf_plugin golang
  install_latest_asdf_language golang
  asdf global golang system
fi

#  Setup lazydocker
if [ "$WITH_ASDF_LAZYDOCKER" = 'yes' ]; then
  fancy_echo "########## Installing latest lazydocker ##########"
  add_or_update_asdf_plugin lazydocker
  install_latest_asdf_language lazydocker latest
  asdf global lazydocker latest
fi

#  Setup lazygit
if [ "$WITH_ASDF_LAZYGIT" = 'yes' ]; then
  fancy_echo "########## Installing latest lazygit ##########"
  add_or_update_asdf_plugin lazygit
  install_latest_asdf_language lazygit latest
  asdf global lazygit latest
fi

#  Setup sops
if [ "$WITH_ASDF_SOPS" = 'yes' ]; then
  fancy_echo "########## Installing latest sops ##########"
  add_or_update_asdf_plugin sops https://github.com/feniix/asdf-sops.git
  install_latest_asdf_language sops latest
  asdf global sops latest
fi

#  Setup step
if [ "$WITH_ASDF_STEP" = 'yes' ]; then
  fancy_echo "########## Installing latest step ##########"
  add_or_update_asdf_plugin step
  install_latest_asdf_language step latest
  asdf global step latest
fi

#  Setup starship
if [ "$WITH_ASDF_STARSHIP" = 'yes' ]; then
  fancy_echo "########## Installing latest starship ##########"
  add_or_update_asdf_plugin starship
  install_latest_asdf_language starship latest
  asdf global starship latest
fi

#  Setup k9s
if [ "$WITH_ASDF_K9S" = 'yes' ]; then
  fancy_echo "########## Installing latest k9s ##########"
  add_or_update_asdf_plugin k9s
  install_latest_asdf_language k9s latest
  asdf global k9s latest
fi

#  Setup k3d
if [ "$WITH_ASDF_K3D" = 'yes' ]; then
  fancy_echo "########## Installing latest k3d ##########"
  add_or_update_asdf_plugin k3d
  install_latest_asdf_language k3d latest
  asdf global k3d latest
fi

#  Setup kubectl
if [ "$WITH_ASDF_KUBECTL" = 'yes' ]; then
  fancy_echo "########## Installing latest kubectl ##########"
  add_or_update_asdf_plugin kubectl https://github.com/asdf-community/asdf-kubectl.git
  install_latest_asdf_language kubectl $KUBECTL_VERSION
  asdf global kubectl $KUBECTL_VERSION
fi

#  Setup istioctl
if [ "$WITH_ASDF_ISTIOCTL" = 'yes' ]; then
  fancy_echo "########## Installing latest istioctl ##########"
  add_or_update_asdf_plugin istioctl https://github.com/virtualstaticvoid/asdf-istioctl.git
  install_latest_asdf_language istioctl latest
  asdf global istioctl latest
fi

# install oh-my-zsh and plugins
OH_MY_ZSH="$HOME/.oh-my-zsh"
OH_MY_ZSH_PLUGINS="$OH_MY_ZSH/custom/plugins"
if [ ! -d "$OH_MY_ZSH" ]; then
  fancy_echo "########## Installing oh-my-zsh ##########"
  ZSH=$OH_MY_ZSH sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  # install zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$OH_MY_ZSH_PLUGINS"/zsh-syntax-highlighting
  # install zsh-history-substring-search
  git clone https://github.com/zsh-users/zsh-history-substring-search "$OH_MY_ZSH_PLUGINS"/zsh-history-substring-search
  # install zsh-completions
  git clone https://github.com/zsh-users/zsh-completions "$OH_MY_ZSH_PLUGINS"/zsh-completions
  # install zsh autosuggestions
  git clone https://github.com/zsh-users/zsh-autosuggestions "$OH_MY_ZSH_PLUGINS"/zsh-autosuggestions
fi

# Setup alacritty-theme
REPO="https://github.com/alacritty/alacritty-theme"
DEST="$HOME/.config/alacritty/themes"
if [ ! -e "$DEST" ]; then
  fancy_echo "########## Install alacritty theme ##########"
  mkdir -p "$DEST"
  git clone $REPO "$DEST"
else
  fancy_echo "########## Updating alacritty-theme ##########"
  cd "$DEST" && git pull origin master
  cd "$cwd"
fi

# Set ZSH as default shell
fancy_echo "########## Setting ZSH as default shell ##########"
if [ "$OS" = 'Linux' ]; then
  if grep "$USER" </etc/passwd | grep -qv 'zsh'; then
    update_shell && echo "set ZSH default shell"
  fi
fi

# Setup bat
BAT_THEMES_DIR="$HOME/.config/bat/themes"
if [ ! -e "$BAT_THEMES_DIR" ]; then
  fancy_echo "########## Install bat themes ##########"
  mkdir "$BAT_THEMES_DIR"
  wget -P "$BAT_THEMES_DIR" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Latte.tmTheme
  wget -P "$BAT_THEMES_DIR" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Frappe.tmTheme
  wget -P "$BAT_THEMES_DIR" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Macchiato.tmTheme
  wget -P "$BAT_THEMES_DIR" https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
  bat cache --build
fi

if [ -r "$HOME/.rcrc" ]; then
  fancy_echo "########## Updating dotfiles ##########"
  rcup -t "$1"
else
  fancy_echo "########## Installing dotfiles ##########"
  rm -f "$HOME"/.zshrc
  env RCRC="$HOME"/.dotfiles/rcrc rcup -t "$1"
fi

if [ -f "$HOME/.laptop.local" ]; then
  fancy_echo "########## Running your customizations from ~/.laptop.local ##########"
  . ../.laptop.local
fi

# Set default terminal theme
echo "night" >"$HOME"/.terminal-theme

# Setup tmux plugin manager
test ! -d ~/.tmux/plugins/tpm &&
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm &&
  ~/.tmux/plugins/tpm/bin/install_plugins
