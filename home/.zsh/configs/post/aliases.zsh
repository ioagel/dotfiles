### Unaliases
# I use 'sp' for spotify command line script
unalias sp 2>/dev/null # oh-my-zsh rails plugin
unalias g 2>/dev/null # oh-my-zsh git plugin

## File System
alias ll="ls -al"
alias ltr="ls -lAFhtr"
alias ln="ln -v"
alias df="df -h"
alias mkdir="mkdir -p"
alias cd="z" # using zoxide utility
# In ubuntu at least, 'fd' is already aliased, and I overwrite it here
# Using the 'fdfind' utility as it is called in Ubuntu
# https://github.com/sharkdp/fd
command -v fdfind >/dev/null && alias fd="fdfind"

## Editor
alias vim='$EDITOR'
alias e='$EDITOR'
alias n='$EDITOR'

# Terminal
# Needed for starship prompt to show properly
# If initialized before the prompt, then use:
# alias fast='fastfetch'
alias fast='fastfetch --pipe false'
alias zel='zellij'

# terminal colors - Valid only when alacritty is teh terminal and old .vimrc exists
#alias day="sed -i '2s/^# //' ~/.dotfiles/config/alacritty/alacritty.toml && ln -sf ~/.dotfiles/vimrc_background ~/.vimrc_background"
#alias night="sed -i '2s/^/# /' ~/.dotfiles/config/alacritty/alacritty.toml && rm -f ~/.vimrc_background"
alias day="echo 'day' > ~/.terminal-theme"
alias night="echo 'night' > ~/.terminal-theme"

# Pretty print the path
alias path='echo $PATH | tr -s ":" "\n"'

# Docker related
alias lzd='lazydocker'

alias lzg='lazygit'

alias ssh="TERM=xterm-256color ssh"

# ssh related
alias sshk="ssh-keygen -R "

# sops encrypt - decrypt related
alias sei="sops -e -i"
alias sdi="sops -d -i"

# kubernetes
alias kns="kubens"
alias kctx="kubectx"

# i3 config
alias i3e='$EDITOR ~/.config/i3/config'

# zsh config
alias soz='source ~/.zshrc'
