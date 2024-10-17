if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH=$HOME/.oh-my-zsh
  ZSH_THEME=""
  HYPHEN_INSENSITIVE="true"
  HIST_STAMPS="dd.mm.yyyy"
  export UPDATE_ZSH_DAYS=7
  COMPLETION_WAITING_DOTS="true"
  # removed 'ssh-agent' because I use 1Password
  plugins=(archlinux colored-man-pages colorize
          common-aliases docker-compose docker dotenv github gitignore
          jsontools npm safe-paste sudo themes tmux yarn vagrant
          history-substring-search asdf fzf zsh-syntax-highlighting
          zsh-autosuggestions terraform kubectl ruby rails)
  ZSH_DISABLE_COMPFIX="true"

  source $ZSH/oh-my-zsh.sh

  #Star Ship
  eval "$(starship init zsh)"
fi
