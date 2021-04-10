# load custom executable functions
for function in ~/.zsh/functions/*; do
  source $function
done

# extra files in ~/.zsh/configs/pre , ~/.zsh/configs , and ~/.zsh/configs/post
# these are loaded first, second, and third, respectively.
_load_settings() {
  _dir="$1"
  if [ -d "$_dir" ]; then
    if [ -d "$_dir/pre" ]; then
      for config in "$_dir"/pre/**/*~*.zwc(N-.); do
        . $config
      done
    fi

    for config in "$_dir"/**/*(N-.); do
      case "$config" in
        "$_dir"/(pre|post)/*|*.zwc)
          :
          ;;
        *)
          . $config
          ;;
      esac
    done

    if [ -d "$_dir/post" ]; then
      for config in "$_dir"/post/**/*~*.zwc(N-.); do
        . $config
      done
    fi
  fi
}
_load_settings "$HOME/.zsh/configs"

# pygments default style
ZSH_COLORIZE_STYLE="solarized-light"

# setup fasd
eval "$(fasd --init auto)"

# asdf completions
. $HOME/.asdf/completions/asdf.bash

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

#[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Compatibility between fzf and zsh-vi-mode
# The plugin will auto execute this zvm_after_init function
function zvm_after_init() {
  [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
}

if [ "$(uname)" = 'Darwin' ]; then
    # installed through Homebrew
    source /usr/local/opt/kube-ps1/share/kube-ps1.sh
else
    source "$HOME"/.config/kube-ps1/kube-ps1.sh
fi
PS1='$(kube_ps1)'$PS1

