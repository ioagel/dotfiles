if [ -d "$HOME/.oh-my-zsh" ]; then
  export ZSH=$HOME/.oh-my-zsh
  ZSH_THEME="spaceship"
  plugins=(fasd brew colored-man-pages colorize common-aliases docker-compose
  docker dotenv github gitignore jsontools npm rails ruby safe-paste sudo themes
  tmux yarn zsh-completions zsh-syntax-highlighting history-substring-search)
  HYPHEN_INSENSITIVE="true"
  HIST_STAMPS="dd/mm/yyyy"
  source $ZSH/oh-my-zsh.sh
fi
