# makes color constants available
autoload -U colors
colors

# enable colored output from ls, etc. on FreeBSD-based systems (Mac OS X)
export CLICOLOR=1

# export BAT_THEME="Gruvbox-Dark-Hard"
# export BAT_THEME="GitHub"
# export BAT_THEME="Solarized (light)"
# export BAT_THEME="OneHalfLight"
export BAT_THEME="gruvbox-dark"

# export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=3"

# pygments default style
export ZSH_COLORIZE_STYLE="solarized-light"

LIGHT_COLOR='base16-one-light.yml'
# LIGHT_COLOR='base16-solarized-light.yml'
# LIGHT_COLOR='base16-tomorrow-night.yml'
DARK_COLOR='base16-gruvbox-dark-hard.yml'
