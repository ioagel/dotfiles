if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH=$HOME/.oh-my-zsh
  ZSH_THEME=""
  HYPHEN_INSENSITIVE="true"
  HIST_STAMPS="dd.mm.yyyy"
  export UPDATE_ZSH_DAYS=7
  COMPLETION_WAITING_DOTS="true"
  plugins=(archlinux ssh-agent fasd brew colored-man-pages colorize
          common-aliases docker-compose docker kubectl dotenv github gitignore
          jsontools npm safe-paste sudo themes tmux yarn vagrant
          history-substring-search asdf fzf zsh-syntax-highlighting
          zsh-autosuggestions terraform)
  ZSH_DISABLE_COMPFIX="true"

  source $ZSH/oh-my-zsh.sh

  #Star Ship
  eval "$(starship init zsh)"
fi