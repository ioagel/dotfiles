# shellcheck disable=SC2034
ZSH=$HOME/.oh-my-zsh

# ZSH_THEME="handled by starhip prompt"
HYPHEN_INSENSITIVE="true"
HIST_STAMPS="dd.mm.yyyy"
COMPLETION_WAITING_DOTS="true"

zstyle ':omz:update' mode reminder # just remind me to update when it's time
zstyle ':omz:update' frequency 7

# removed 'ssh-agent' because I use 1Password
# shellcheck disable=SC2034
plugins=(
    vi-mode
    zsh-syntax-highlighting
    zsh-autosuggestions
    history-substring-search
    extract
    archlinux
    colored-man-pages
    colorize
    common-aliases
    docker
    dotenv
    safe-paste
    sudo
    vagrant
    fzf
    kubectl
    rails
    zoxide
    web-search
    copyfile
    copybuffer
    mise
)

ZSH_DISABLE_COMPFIX="true"

# vi-mode plugin configuration
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true

source "$ZSH"/oh-my-zsh.sh
