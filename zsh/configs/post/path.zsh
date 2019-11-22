# Try loading ASDF from the regular home dir location
if [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
elif which brew >/dev/null &&
  BREW_DIR="$(dirname `which brew`)/.." &&
  [ -f "$BREW_DIR/opt/asdf/asdf.sh" ]; then
  . "$BREW_DIR/opt/asdf/asdf.sh"
fi

PATH="/usr/local/sbin:$PATH"

# we install manually the latest version of go in linux
export GOPATH="$HOME/go"
if [ "$(uname)" = 'Linux' ]; then
  PATH="/usr/local/go/bin:$GOPATH/bin:$PATH"
else
  PATH="$GOPATH/bin:$PATH"
fi
# mkdir .git/safe in the root of repositories you trust
PATH=".git/safe/../../bin:$PATH"

export -U PATH
