if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH=$HOME/.oh-my-zsh
  ZSH_THEME="spaceship"
  HYPHEN_INSENSITIVE="true"
  HIST_STAMPS="dd/mm/yyyy"
  export UPDATE_ZSH_DAYS=7
  COMPLETION_WAITING_DOTS="true"
  plugins=(fasd brew colored-man-pages colorize common-aliases docker-compose
  docker kubectl dotenv github gitignore jsontools npm safe-paste sudo themes
  tmux yarn zsh-completions zsh-syntax-highlighting history-substring-search
  zsh-autosuggestions)
  ZSH_DISABLE_COMPFIX="true"
  source $ZSH/oh-my-zsh.sh
fi
