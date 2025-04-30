setopt hist_ignore_all_dups \
       inc_append_history \
       share_history \
       hist_reduce_blanks \
       hist_verify \
       hist_find_no_dups \
       hist_save_no_dups \
       append_history \
       extended_history \
       hist_ignore_space

HISTFILE=~/.zhistory
HISTSIZE=50000
SAVEHIST=50000

# These need to be sourced after oh-my-zsh (used by history-substring-search plugin)
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
