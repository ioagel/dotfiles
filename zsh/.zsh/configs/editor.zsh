export VISUAL=vim

if type nvim > /dev/null 2>&1; then
  export VISUAL=nvim
fi

export EDITOR=$VISUAL
