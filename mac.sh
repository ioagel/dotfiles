#!/bin/sh

HOMEBREW_PREFIX="/usr/local"

if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" /usr/local
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi

if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew ..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

if brew list | grep -Fq brew-cask; then
  fancy_echo "Uninstalling old Homebrew-Cask ..."
  brew uninstall --force brew-cask
fi

fancy_echo "Updating Homebrew formulae ..."
brew update --force # https://github.com/Homebrew/brew/issues/1151

if [ "$WITH_ASDF_PYTHON" = 'no' ]; then
  brew install python
fi
if [ "$WITH_ASDF_GO" = 'no' ]; then
  brew install go
fi
if [ "$WITH_ASDF_ruby" = 'no' ]; then
  brew install ruby
  export PATH="/usr/local/opt/ruby/bin:$PATH"
  gem install --user-install neovim
  gem install --user-install solargraph
  gem install --user-install tmuxinator
fi

brew bundle --file=~/.dotfiles/Brewfile

if command -v /Applications/iTerm.app/Contents/MacOS/iTerm2 >/dev/null; then
  fancy_echo "Setup sync for iTerm2 Prefs in a custom folder ..."
  killall cfprefsd # This will get rid of cached settings
  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.dotfiles/iterm2"
  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
fi
