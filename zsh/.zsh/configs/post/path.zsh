export GOPATH="$HOME/.golang"
PATH="$GOPATH/bin:$PATH"

export ASDF_GOLANG_MOD_VERSION_ENABLED=true

# adds gnu-sed from brew path in front
if [ "$(uname)" = 'Darwin' ]; then
    PATH="/usr/local/opt/gnu-sed/libexec/gnubin:$PATH"
fi

# home dir bin dirs
PATH="$HOME/.bin:$HOME/.local/bin:$HOME/.linkerd2/bin:$PATH"

# mkdir .git/safe in the root of repositories you trust
PATH=".git/safe/../../bin:$PATH"

export LIBVIRT_DEFAULT_URI="qemu:///system"

export -U PATH
