#!/usr/bin/env bash
# NOTE: hitting the GitHub api without an auth token limits the requests
# at 60/hour.

snapd="$(snap version 2> /dev/null | sed -n 2p | awk '{print $2}')"

# add required repositories
sudo add-apt-repository -y universe

sudo apt -y update

sudo apt -y install \
  autoconf automake build-essential python-dev libtool libssl-dev pkg-config \
  libreadline-dev libncurses-dev coreutils libyaml-dev libxslt-dev \
  libffi-dev unixodbc-dev unzip curl gnupg git tmux \
  rcm zsh htop unixodbc fasd shellcheck jq tree wget silversearcher-ag cmake \
  apt-transport-https ca-certificates zlib1g-dev ripgrep bat nala fdfind

# Install gui apps and fonts
if [ "$WITH_GUI" = 'yes' ]; then
  sudo apt -y update

  sudo apt -y install fontconfig fonts-firacode alacritty firefox vlc \
    calibre xclip

  ########### Install Fonts #############
  #### adobe source pro fonts
  # Source Code Pro
  wget -P /tmp https://github.com/adobe-fonts/source-code-pro/archive/refs/tags/2.042R-u/1.062R-i/1.026R-vf.zip
  unzip /tmp/1.026R-vf.zip -d /tmp
  mkdir -p ~/.local/share/fonts/adobe/source-code-pro
  mv -f /tmp/source-code-pro-2.042R-u-1.062R-i-1.026R-vf/OTF/*.otf ~/.local/share/fonts/adobe/source-code-pro/
  rm -rf /tmp/source-code-pro-2.042R-u-1.062R-i-1.026R-vf /tmp/1.026R-vf.zip
  # Source Serif Pro
  wget -P /tmp https://github.com/adobe-fonts/source-serif/archive/refs/tags/4.005R.zip
  unzip /tmp/4.005R.zip -d /tmp
  mkdir -p ~/.local/share/fonts/adobe/source-serif-pro
  mv -f /tmp/source-serif-4.005R/OTF/*.otf ~/.local/share/fonts/adobe/source-serif-pro/
  rm -rf /tmp/source-serif-4.005R /tmp/4.005R.zip
  # Source Sans Pro
  wget -P /tmp https://github.com/adobe-fonts/source-sans/archive/refs/tags/3.052R.zip
  unzip /tmp/3.052R.zip -d /tmp
  mkdir -p ~/.local/share/fonts/adobe/source-sans-pro
  mv -f /tmp/source-sans-3.052R/OTF/*.otf ~/.local/share/fonts/adobe/source-sans-pro/
  rm -rf /tmp/source-sans-3.052R /tmp/3.052R.zip
  #### nerd fonts
  mkdir -p ~/.local/share/fonts/nerd/{FiraCode,SourceCodePro,Hasklig}

  wget -P /tmp https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
  unzip /tmp/FiraCode.zip -d /tmp/FiraCode
  mv -f /tmp/FiraCode/*.ttf ~/.local/share/fonts/nerd/FiraCode/
  rm -rf /tmp/FiraCode*
  wget -P /tmp https://github.com/ryanoasis/nerd-fonts/releases/latest/download/SourceCodePro.zip
  unzip /tmp/SourceCodePro.zip -d /tmp/SourceCodePro
  mv -f /tmp/SourceCodePro/*.ttf ~/.local/share/fonts/nerd/SourceCodePro/
  rm -rf /tmp/SourceCodePro*
  wget -P /tmp https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hasklig.zip
  unzip /tmp/Hasklig.zip -d /tmp/Hasklig
  mv -f /tmp/Hasklig/*.otf ~/.local/share/fonts/nerd/Hasklig/
  rm -rf /tmp/Hasklig*

  fc-cache -fr
  ##########################

#  if [ "$snapd" != 'unavailable' ]; then
#    sudo snap install code --classic
#    sudo snap install spotify
#  fi

  wget -P /tmp https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i /tmp/google-chrome-stable_current_amd64.deb
  rm -rf /tmp/google-chrome*
fi

# check for env variable WITH_JAVA before installing java/maven support
if [ "$WITH_JAVA" = 'yes' ]; then
  sudo apt -y install maven
fi
