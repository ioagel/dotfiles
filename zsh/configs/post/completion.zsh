# load our own completion functions
fpath=(${ASDF_DIR}/completions ~/.zsh/completion /usr/local/share/zsh/site-functions $fpath)
autoload -Uz compinit && compinit

# NOTE: commented the following code because asdf completion fail
# completion; use cache if updated within 24h
# autoload -Uz compinit
# if [[ -n $HOME/.zcompdump(#qN.mh+24) ]]; then
#   compinit -d $HOME/.zcompdump;
# else
#   compinit -C;
# fi;

# disable zsh bundled function mtools command mcd
# which causes a conflict.
compdef -d mcd

bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
