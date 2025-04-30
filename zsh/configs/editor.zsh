if type nvim > /dev/null 2>&1; then
  export EDITOR=nvim
else
  export EDITOR=vim
fi

export VISUAL=$EDITOR
export SUDO_EDITOR=$EDITOR