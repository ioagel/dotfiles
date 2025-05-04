# Initialize Starship
# Load starship here, because when doing it as a oh-my-zsh plugin, it breaks the _load_settings function
# The "post" directory contents are not loaded when doing it as a oh-my-zsh plugin
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"
