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

# setup fasd
eval "$(fasd --init auto)"

# asdf completions
. $HOME/.asdf/completions/asdf.bash

# JAVA_HOME through asdf java plugin
#. ~/.asdf/plugins/java/set-java-home.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# I disabled it because i use the one provided by 'spaceship' prompt in
# oh-my-zsh
# if [ "$(uname)" = 'Darwin' ]; then
#     # installed through Homebrew
#     source /usr/local/opt/kube-ps1/share/kube-ps1.sh
# else
#     source "$HOME"/.config/kube-ps1/kube-ps1.sh
# fi
# PS1='$(kube_ps1)'$PS1

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# aliases
[[ -f ~/.aliases ]] && source ~/.aliases

