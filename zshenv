local _old_path="$PATH"

# Local config
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local

if [[ $PATH != $_old_path ]]; then
  # `colors` isn't initialized yet, so define a few manually
  typeset -AHg fg fg_bold
  if [ -t 2 ]; then
    fg[red]=$'\e[31m'
    fg_bold[white]=$'\e[1;37m'
    reset_color=$'\e[m'
  else
    fg[red]=""
    fg_bold[white]=""
    reset_color=""
  fi

  cat <<MSG >&2
${fg[red]}Warning:${reset_color} your \`~/.zshenv.local' configuration seems to edit PATH entries.
Please move that configuration to \`.zshrc.local' like so:
  ${fg_bold[white]}cat ~/.zshenv.local >> ~/.zshrc.local && rm ~/.zshenv.local${reset_color}

(called from ${(%):-%N:%i})

MSG
fi

unset _old_path

# if [ -r ~/.terminfo/78/xterm-256color-italic ] && [ -r ~/.terminfo/74/tmux-256color ]; then
#   if [[ -z "$TMUX" ]]; then
#     export TERM=xterm-256color-italic
#   else
#     export TERM=tmux-256color
#   fi
# else
#   export TERM=xterm-256color
# fi
#
# if [[ -r ~/.terminfo/61/alacritty ]]; then
#     export TERM=alacritty
# else
#   export TERM=xterm-256color
# fi
