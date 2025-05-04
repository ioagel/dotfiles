# load our own completion and function paths
# shellcheck disable=SC2206
fpath=($ZSH_DIR/functions $ZSH_DIR/completion /usr/local/share/zsh/site-functions $fpath)

# Autoload specific functions we want available
autoload -U change-extension
autoload -U cs
autoload -U envup
autoload -U fs
autoload -U g
autoload -U genpass
autoload -U mcd
# Add other autoload lines here if needed

# Initialize completion system
autoload -Uz compinit && compinit