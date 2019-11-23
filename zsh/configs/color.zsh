# makes color constants available
autoload -U colors
colors

# enable colored output from ls, etc. on FreeBSD-based systems
export CLICOLOR=1

# fix bat colors for light theme
# export BAT_THEME="OneHalfDark" # for dark terminal themes
export BAT_THEME="Solarized (light)" # for light terminal themes
